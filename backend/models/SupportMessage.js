const mongoose = require('mongoose');

const supportMessageSchema = new mongoose.Schema(
  {
    ticketId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ticket',
      required: [true, 'Ticket is required'],
    },
    senderType: {
      type: String,
      enum: ['user', 'admin'],
      required: [true, 'Sender type is required'],
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Sender is required'],
    },
    message: {
      type: String,
      default: '',
      trim: true,
    },
    imageUrl: {
      type: String,
      default: null,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

supportMessageSchema.index({ ticketId: 1, createdAt: 1 });

module.exports = mongoose.model('SupportMessage', supportMessageSchema);
