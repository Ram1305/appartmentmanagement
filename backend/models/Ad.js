const mongoose = require('mongoose');

const adSchema = new mongoose.Schema(
  {
    image: {
      type: String,
      required: [true, 'Ad image URL is required'],
    },
    displayOrder: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Admin',
    },
  },
  {
    timestamps: true,
  }
);

adSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

adSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Ad', adSchema);
