const mongoose = require('mongoose');

const guardMessageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: [true, 'Conversation ID is required'],
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Sender ID is required'],
      refPath: 'senderType',
    },
    senderType: {
      type: String,
      enum: ['security', 'user'],
      required: [true, 'Sender type is required'],
    },
    recipientId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Recipient ID is required'],
      refPath: 'recipientType',
    },
    recipientType: {
      type: String,
      enum: ['security', 'user'],
      required: [true, 'Recipient type is required'],
    },
    message: {
      type: String,
      required: [true, 'Message is required'],
      trim: true,
      maxlength: [2000, 'Message cannot exceed 2000 characters'],
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    readAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for efficient message queries
guardMessageSchema.index({ conversationId: 1, createdAt: -1 });

// Index for unread count queries
guardMessageSchema.index({ recipientId: 1, isRead: 1 });

// Index for conversation messages pagination
guardMessageSchema.index({ conversationId: 1, createdAt: 1 });

module.exports = mongoose.model('GuardMessage', guardMessageSchema);
