const Conversation = require('../models/Conversation');
const GuardMessage = require('../models/GuardMessage');
const User = require('../models/User');
const Security = require('../models/Security');

// @desc    Get all conversations for logged-in user
// @route   GET /api/guard-messages/conversations
// @access  Private
exports.getConversations = async (req, res) => {
  try {
    const userId = req.userId;

    // First, determine if user is security or regular user
    let userType = 'user';
    let user = await User.findById(userId);

    if (!user) {
      user = await Security.findById(userId);
      userType = 'security';
    }

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Build query based on user type
    const query =
      userType === 'security' ? { securityId: userId } : { userId: userId };

    // Get conversations with populated participants
    const conversations = await Conversation.find(query)
      .populate('security', 'name profilePic mobileNumber')
      .populate('user', 'name profilePic block floor roomNumber mobileNumber')
      .sort({ lastMessageAt: -1 });

    // Transform conversations for response
    const transformedConversations = conversations.map((conv) => {
      const unreadCount =
        userType === 'security' ? conv.unreadCountSecurity : conv.unreadCountUser;

      return {
        _id: conv._id,
        securityId: conv.securityId,
        userId: conv.userId,
        securityName: conv.security?.name || 'Security Guard',
        securityProfilePic: conv.security?.profilePic || null,
        securityMobile: conv.security?.mobileNumber || null,
        userName: conv.user?.name || 'Tenant',
        userProfilePic: conv.user?.profilePic || null,
        userBlock: conv.user?.block || null,
        userFloor: conv.user?.floor || null,
        userRoomNumber: conv.user?.roomNumber || null,
        userMobile: conv.user?.mobileNumber || null,
        lastMessage: conv.lastMessage,
        lastMessageAt: conv.lastMessageAt,
        lastMessageSenderType: conv.lastMessageSenderType,
        unreadCount,
        createdAt: conv.createdAt,
        updatedAt: conv.updatedAt,
      };
    });

    res.json({
      success: true,
      conversations: transformedConversations,
      userType,
    });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ error: 'Failed to get conversations' });
  }
};

// @desc    Get messages in a conversation
// @route   GET /api/guard-messages/conversations/:conversationId
// @access  Private
exports.getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.userId;
    const { page = 1, limit = 50 } = req.query;

    // Verify conversation exists and user is a participant
    const conversation = await Conversation.findById(conversationId);

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    const isParticipant =
      conversation.securityId.toString() === userId ||
      conversation.userId.toString() === userId;

    if (!isParticipant) {
      return res
        .status(403)
        .json({ error: 'Not authorized to view this conversation' });
    }

    // Get messages with pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const messages = await GuardMessage.find({ conversationId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await GuardMessage.countDocuments({ conversationId });

    // Reverse to get chronological order
    const sortedMessages = messages.reverse();

    res.json({
      success: true,
      messages: sortedMessages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Failed to get messages' });
  }
};

// @desc    Send a message
// @route   POST /api/guard-messages/send
// @access  Private
exports.sendMessage = async (req, res) => {
  try {
    const { recipientId, message, conversationId } = req.body;
    const senderId = req.userId;

    if (!message || !message.trim()) {
      return res.status(400).json({ error: 'Message is required' });
    }

    if (!recipientId && !conversationId) {
      return res
        .status(400)
        .json({ error: 'Recipient ID or Conversation ID is required' });
    }

    // Determine sender type
    let senderType = 'user';
    let sender = await User.findById(senderId);

    if (!sender) {
      sender = await Security.findById(senderId);
      senderType = 'security';
    }

    if (!sender) {
      return res.status(404).json({ error: 'Sender not found' });
    }

    let conversation;

    if (conversationId) {
      // Use existing conversation
      conversation = await Conversation.findById(conversationId);
      if (!conversation) {
        return res.status(404).json({ error: 'Conversation not found' });
      }
    } else {
      // Create or get conversation
      let securityId, userId;

      if (senderType === 'security') {
        securityId = senderId;
        userId = recipientId;
      } else {
        securityId = recipientId;
        userId = senderId;
      }

      conversation = await Conversation.findOrCreate(securityId, userId);
    }

    // Determine recipient info
    const recipientType = senderType === 'security' ? 'user' : 'security';
    const actualRecipientId =
      senderType === 'security' ? conversation.userId : conversation.securityId;

    // Create the message
    const newMessage = await GuardMessage.create({
      conversationId: conversation._id,
      senderId,
      senderType,
      recipientId: actualRecipientId,
      recipientType,
      message: message.trim(),
      isRead: false,
    });

    // Update conversation
    await conversation.updateLastMessage(message.trim(), senderType);

    // Emit Socket.IO event if io is available
    const io = req.app.get('io');
    if (io) {
      const messageData = {
        _id: newMessage._id,
        conversationId: conversation._id,
        senderId,
        senderType,
        senderName: sender.name,
        recipientId: actualRecipientId,
        recipientType,
        message: newMessage.message,
        isRead: false,
        createdAt: newMessage.createdAt,
      };

      // Emit to conversation room
      io.to(`conversation_${conversation._id}`).emit('new_message', messageData);

      // Emit notification to recipient
      io.to(`user_${actualRecipientId}`).emit('new_message_notification', {
        conversationId: conversation._id,
        senderId,
        senderType,
        senderName: sender.name,
        message: newMessage.message,
        createdAt: newMessage.createdAt,
      });
    }

    res.status(201).json({
      success: true,
      message: newMessage,
      conversationId: conversation._id,
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
};

// @desc    Mark messages as read
// @route   PUT /api/guard-messages/:messageId/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.userId;

    const message = await GuardMessage.findById(messageId);

    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Only recipient can mark as read
    if (message.recipientId.toString() !== userId) {
      return res
        .status(403)
        .json({ error: 'Not authorized to mark this message as read' });
    }

    message.isRead = true;
    message.readAt = new Date();
    await message.save();

    // Update conversation unread count
    const conversation = await Conversation.findById(message.conversationId);
    if (conversation) {
      // Determine user type
      let userType = 'user';
      const isSecurityUser = await Security.findById(userId);
      if (isSecurityUser) {
        userType = 'security';
      }
      await conversation.markAsRead(userType);
    }

    res.json({
      success: true,
      message: 'Message marked as read',
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'Failed to mark message as read' });
  }
};

// @desc    Mark all messages in conversation as read
// @route   PUT /api/guard-messages/conversations/:conversationId/read
// @access  Private
exports.markConversationAsRead = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.userId;

    const conversation = await Conversation.findById(conversationId);

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Verify user is participant
    const isParticipant =
      conversation.securityId.toString() === userId ||
      conversation.userId.toString() === userId;

    if (!isParticipant) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    // Determine user type
    let userType = 'user';
    const isSecurityUser = await Security.findById(userId);
    if (isSecurityUser) {
      userType = 'security';
    }

    // Mark all unread messages as read
    await GuardMessage.updateMany(
      {
        conversationId,
        recipientId: userId,
        isRead: false,
      },
      {
        isRead: true,
        readAt: new Date(),
      }
    );

    // Update conversation
    await conversation.markAsRead(userType);

    // Emit Socket.IO event
    const io = req.app.get('io');
    if (io) {
      const otherParticipantId =
        userType === 'security' ? conversation.userId : conversation.securityId;

      io.to(`user_${otherParticipantId}`).emit('messages_read', {
        conversationId,
        readBy: userId,
        readByType: userType,
      });
    }

    res.json({
      success: true,
      message: 'All messages marked as read',
    });
  } catch (error) {
    console.error('Mark conversation as read error:', error);
    res.status(500).json({ error: 'Failed to mark conversation as read' });
  }
};

// @desc    Get total unread count
// @route   GET /api/guard-messages/unread-count
// @access  Private
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.userId;

    // Count unread messages where user is recipient
    const unreadCount = await GuardMessage.countDocuments({
      recipientId: userId,
      isRead: false,
    });

    res.json({
      success: true,
      unreadCount,
    });
  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({ error: 'Failed to get unread count' });
  }
};

// @desc    Get list of security guards (for tenants to start chat)
// @route   GET /api/guard-messages/security-list
// @access  Private
exports.getSecurityList = async (req, res) => {
  try {
    const securities = await Security.find({
      isActive: true,
      status: 'approved',
    }).select('name profilePic mobileNumber');

    res.json({
      success: true,
      securities,
    });
  } catch (error) {
    console.error('Get security list error:', error);
    res.status(500).json({ error: 'Failed to get security list' });
  }
};

// @desc    Get list of tenants (for security to start chat)
// @route   GET /api/guard-messages/tenant-list
// @access  Private
exports.getTenantList = async (req, res) => {
  try {
    const { search } = req.query;

    let query = {
      isActive: true,
      status: 'approved',
    };

    // Add search filter if provided
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { block: { $regex: search, $options: 'i' } },
        { roomNumber: { $regex: search, $options: 'i' } },
      ];
    }

    const tenants = await User.find(query)
      .select('name profilePic block floor roomNumber mobileNumber')
      .sort({ block: 1, floor: 1, roomNumber: 1 });

    res.json({
      success: true,
      tenants,
    });
  } catch (error) {
    console.error('Get tenant list error:', error);
    res.status(500).json({ error: 'Failed to get tenant list' });
  }
};

// @desc    Get or create conversation with recipient
// @route   POST /api/guard-messages/conversation
// @access  Private
exports.getOrCreateConversation = async (req, res) => {
  try {
    const { recipientId } = req.body;
    const senderId = req.userId;

    if (!recipientId) {
      return res.status(400).json({ error: 'Recipient ID is required' });
    }

    // Determine sender type
    let senderType = 'user';
    let sender = await User.findById(senderId);

    if (!sender) {
      sender = await Security.findById(senderId);
      senderType = 'security';
    }

    if (!sender) {
      return res.status(404).json({ error: 'Sender not found' });
    }

    // Determine security and user IDs
    let securityId, userId;

    if (senderType === 'security') {
      securityId = senderId;
      userId = recipientId;
    } else {
      securityId = recipientId;
      userId = senderId;
    }

    // Find or create conversation
    const conversation = await Conversation.findOrCreate(securityId, userId);

    // Populate participant details
    await conversation.populate([
      { path: 'security', select: 'name profilePic mobileNumber' },
      { path: 'user', select: 'name profilePic block floor roomNumber mobileNumber' },
    ]);

    const unreadCount =
      senderType === 'security'
        ? conversation.unreadCountSecurity
        : conversation.unreadCountUser;

    res.json({
      success: true,
      conversation: {
        _id: conversation._id,
        securityId: conversation.securityId,
        userId: conversation.userId,
        securityName: conversation.security?.name || 'Security Guard',
        securityProfilePic: conversation.security?.profilePic || null,
        userName: conversation.user?.name || 'Tenant',
        userProfilePic: conversation.user?.profilePic || null,
        userBlock: conversation.user?.block || null,
        userFloor: conversation.user?.floor || null,
        userRoomNumber: conversation.user?.roomNumber || null,
        lastMessage: conversation.lastMessage,
        lastMessageAt: conversation.lastMessageAt,
        unreadCount,
      },
    });
  } catch (error) {
    console.error('Get or create conversation error:', error);
    res.status(500).json({ error: 'Failed to get or create conversation' });
  }
};
