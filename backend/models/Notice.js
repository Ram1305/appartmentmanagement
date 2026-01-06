const mongoose = require('mongoose');

const noticeSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Notice title is required'],
      trim: true,
    },
    content: {
      type: String,
      required: [true, 'Notice content is required'],
    },
    type: {
      type: String,
      enum: ['general', 'maintenance', 'payment', 'event', 'urgent'],
      default: 'general',
    },
    targetAudience: {
      type: String,
      enum: ['all', 'tenants', 'managers', 'security'],
      default: 'all',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },
    expiryDate: {
      type: Date,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
  }
);

noticeSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

noticeSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Notice', noticeSchema);

