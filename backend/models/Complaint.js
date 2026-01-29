const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
    },
    type: {
      type: String,
      required: [true, 'Complaint type is required'],
      enum: ['plumbing', 'electrical', 'cleaning', 'maintenance', 'security', 'other'],
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
    },
    block: { type: String, trim: true, default: '' },
    floor: { type: String, trim: true, default: '' },
    roomNumber: { type: String, trim: true, default: '' },
    status: {
      type: String,
      enum: ['pending', 'approved', 'completed', 'cancelled'],
      default: 'pending',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Complaint', complaintSchema);
