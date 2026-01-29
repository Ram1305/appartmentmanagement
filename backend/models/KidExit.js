const mongoose = require('mongoose');

const kidExitSchema = new mongoose.Schema(
  {
    reportedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Reporter (user) is required'],
    },
    kidName: {
      type: String,
      required: [true, 'Kid name is required'],
      trim: true,
    },
    familyMemberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'FamilyMember',
      default: null,
    },
    block: {
      type: String,
      required: [true, 'Block is required'],
      trim: true,
    },
    homeNumber: {
      type: String,
      required: [true, 'Home number is required'],
      trim: true,
    },
    exitTime: {
      type: Date,
      required: [true, 'Exit time is required'],
      default: Date.now,
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
    acknowledgedAt: {
      type: Date,
      default: null,
    },
    acknowledgedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Security',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

kidExitSchema.index({ block: 1, homeNumber: 1 });
kidExitSchema.index({ exitTime: -1 });
kidExitSchema.index({ reportedBy: 1 });

module.exports = mongoose.model('KidExit', kidExitSchema);
