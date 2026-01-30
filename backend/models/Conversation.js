const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema(
  {
    securityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Security',
      required: [true, 'Security ID is required'],
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
    },
    lastMessage: {
      type: String,
      default: '',
    },
    lastMessageAt: {
      type: Date,
      default: Date.now,
    },
    lastMessageSenderType: {
      type: String,
      enum: ['security', 'user'],
    },
    unreadCountSecurity: {
      type: Number,
      default: 0,
    },
    unreadCountUser: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Unique compound index to ensure only one conversation per security-user pair
conversationSchema.index({ securityId: 1, userId: 1 }, { unique: true });

// Index for fetching conversations sorted by last message
conversationSchema.index({ lastMessageAt: -1 });

// Index for security's conversations
conversationSchema.index({ securityId: 1, lastMessageAt: -1 });

// Index for user's conversations
conversationSchema.index({ userId: 1, lastMessageAt: -1 });

// Virtual for security details
conversationSchema.virtual('security', {
  ref: 'Security',
  localField: 'securityId',
  foreignField: '_id',
  justOne: true,
});

// Virtual for user details
conversationSchema.virtual('user', {
  ref: 'User',
  localField: 'userId',
  foreignField: '_id',
  justOne: true,
});

// Static method to find or create conversation (atomic to avoid E11000 race condition)
conversationSchema.statics.findOrCreate = async function (securityId, userId) {
  const conversation = await this.findOneAndUpdate(
    { securityId, userId },
    {
      $setOnInsert: {
        securityId,
        userId,
        lastMessage: '',
        lastMessageAt: new Date(),
        unreadCountSecurity: 0,
        unreadCountUser: 0,
        isActive: true,
      },
    },
    { new: true, upsert: true }
  );
  return conversation;
};

// Method to update last message
conversationSchema.methods.updateLastMessage = async function (
  message,
  senderType
) {
  this.lastMessage = message.substring(0, 100); // Truncate for preview
  this.lastMessageAt = new Date();
  this.lastMessageSenderType = senderType;

  // Increment unread count for recipient
  if (senderType === 'security') {
    this.unreadCountUser += 1;
  } else {
    this.unreadCountSecurity += 1;
  }

  return this.save();
};

// Method to mark messages as read
conversationSchema.methods.markAsRead = async function (userType) {
  if (userType === 'security') {
    this.unreadCountSecurity = 0;
  } else {
    this.unreadCountUser = 0;
  }

  return this.save();
};

module.exports = mongoose.model('Conversation', conversationSchema);
