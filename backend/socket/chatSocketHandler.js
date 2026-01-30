const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Security = require('../models/Security');
const Conversation = require('../models/Conversation');
const GuardMessage = require('../models/GuardMessage');

// Store online users: { odId: socketId }
const onlineUsers = new Map();

module.exports = (io) => {
  // Authentication middleware for Socket.IO
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;

      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }

      // Verify JWT token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      if (!decoded.userId) {
        return next(new Error('Authentication error: Invalid token'));
      }

      // Try to find user in User collection first, then Security
      let user = await User.findById(decoded.userId);
      let userType = 'user';

      if (!user) {
        user = await Security.findById(decoded.userId);
        userType = 'security';
      }

      if (!user) {
        return next(new Error('Authentication error: User not found'));
      }

      // Attach user info to socket
      socket.userId = decoded.userId;
      socket.userType = userType;
      socket.userName = user.name;

      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      next(new Error('Authentication error: ' + error.message));
    }
  });

  io.on('connection', (socket) => {
    console.log(
      `User connected: ${socket.userName} (${socket.userType}) - Socket ID: ${socket.id}`
    );

    // Add user to online users map
    onlineUsers.set(socket.userId, socket.id);

    // Broadcast online status to relevant users
    io.emit('user_online', {
      odId: socket.userId,
      userType: socket.userType,
    });

    // Join user's personal room for direct messages
    socket.join(`user_${socket.userId}`);

    // Handle joining a conversation room
    socket.on('join_conversation', async (data) => {
      try {
        const { conversationId } = data;

        if (!conversationId) {
          return socket.emit('error', { message: 'Conversation ID is required' });
        }

        // Verify user is part of this conversation
        const conversation = await Conversation.findById(conversationId);

        if (!conversation) {
          return socket.emit('error', { message: 'Conversation not found' });
        }

        const isParticipant =
          conversation.securityId.toString() === socket.userId ||
          conversation.userId.toString() === socket.userId;

        if (!isParticipant) {
          return socket.emit('error', {
            message: 'Not authorized to join this conversation',
          });
        }

        // Join the conversation room
        socket.join(`conversation_${conversationId}`);
        console.log(
          `${socket.userName} joined conversation: ${conversationId}`
        );

        socket.emit('joined_conversation', { conversationId });
      } catch (error) {
        console.error('Error joining conversation:', error);
        socket.emit('error', { message: 'Failed to join conversation' });
      }
    });

    // Handle leaving a conversation room
    socket.on('leave_conversation', (data) => {
      const { conversationId } = data;
      if (conversationId) {
        socket.leave(`conversation_${conversationId}`);
        console.log(`${socket.userName} left conversation: ${conversationId}`);
      }
    });

    // Handle sending a message
    socket.on('send_message', async (data) => {
      try {
        const { conversationId, recipientId, message } = data;

        if (!message || !message.trim()) {
          return socket.emit('error', { message: 'Message cannot be empty' });
        }

        let conversation;

        // Get or create conversation
        if (conversationId) {
          conversation = await Conversation.findById(conversationId);
        } else if (recipientId) {
          // Determine security and user IDs based on sender type
          let securityId, userId;

          if (socket.userType === 'security') {
            securityId = socket.userId;
            userId = recipientId;
          } else {
            securityId = recipientId;
            userId = socket.userId;
          }

          conversation = await Conversation.findOrCreate(securityId, userId);
        }

        if (!conversation) {
          return socket.emit('error', { message: 'Failed to get conversation' });
        }

        // Determine recipient type
        const recipientType = socket.userType === 'security' ? 'user' : 'security';
        const actualRecipientId =
          socket.userType === 'security'
            ? conversation.userId
            : conversation.securityId;

        // Create the message
        const newMessage = await GuardMessage.create({
          conversationId: conversation._id,
          senderId: socket.userId,
          senderType: socket.userType,
          recipientId: actualRecipientId,
          recipientType: recipientType,
          message: message.trim(),
          isRead: false,
        });

        // Update conversation with last message
        await conversation.updateLastMessage(message.trim(), socket.userType);

        // Prepare message data for broadcast
        const messageData = {
          _id: newMessage._id,
          conversationId: conversation._id,
          senderId: socket.userId,
          senderType: socket.userType,
          senderName: socket.userName,
          recipientId: actualRecipientId,
          recipientType: recipientType,
          message: newMessage.message,
          isRead: false,
          createdAt: newMessage.createdAt,
        };

        // Broadcast to conversation room
        io.to(`conversation_${conversation._id}`).emit(
          'new_message',
          messageData
        );

        // Also send to recipient's personal room (for notification even if not in conversation)
        io.to(`user_${actualRecipientId}`).emit('new_message_notification', {
          conversationId: conversation._id,
          senderId: socket.userId,
          senderType: socket.userType,
          senderName: socket.userName,
          message: newMessage.message,
          createdAt: newMessage.createdAt,
        });

        // Send confirmation to sender
        socket.emit('message_sent', messageData);

        console.log(
          `Message sent from ${socket.userName} in conversation ${conversation._id}`
        );
      } catch (error) {
        console.error('Error sending message:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Handle marking messages as read
    socket.on('mark_as_read', async (data) => {
      try {
        const { conversationId } = data;

        if (!conversationId) {
          return socket.emit('error', { message: 'Conversation ID is required' });
        }

        const conversation = await Conversation.findById(conversationId);

        if (!conversation) {
          return socket.emit('error', { message: 'Conversation not found' });
        }

        // Update all unread messages in this conversation for the current user
        await GuardMessage.updateMany(
          {
            conversationId,
            recipientId: socket.userId,
            isRead: false,
          },
          {
            isRead: true,
            readAt: new Date(),
          }
        );

        // Reset unread count in conversation
        await conversation.markAsRead(socket.userType);

        // Notify the other participant that messages were read
        const otherParticipantId =
          socket.userType === 'security'
            ? conversation.userId
            : conversation.securityId;

        io.to(`user_${otherParticipantId}`).emit('messages_read', {
          conversationId,
          readBy: socket.userId,
          readByType: socket.userType,
        });

        socket.emit('marked_as_read', { conversationId });
      } catch (error) {
        console.error('Error marking messages as read:', error);
        socket.emit('error', { message: 'Failed to mark messages as read' });
      }
    });

    // Handle typing indicator
    socket.on('typing', (data) => {
      const { conversationId, isTyping } = data;

      if (!conversationId) return;

      // Broadcast typing status to conversation room (except sender)
      socket.to(`conversation_${conversationId}`).emit('user_typing', {
        conversationId,
        userId: socket.userId,
        userType: socket.userType,
        userName: socket.userName,
        isTyping,
      });
    });

    // Handle getting online status
    socket.on('check_online', (data) => {
      const { userId } = data;
      const isOnline = onlineUsers.has(userId);
      socket.emit('online_status', { userId, isOnline });
    });

    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.userName} (${socket.userType})`);

      // Remove from online users
      onlineUsers.delete(socket.userId);

      // Broadcast offline status
      io.emit('user_offline', {
        odId: socket.userId,
        userType: socket.userType,
      });
    });
  });
};
