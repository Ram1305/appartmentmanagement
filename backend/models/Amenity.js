const mongoose = require('mongoose');

const amenitySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Amenity name is required'],
      trim: true,
    },
    isEnabled: {
      type: Boolean,
      default: true,
    },
    displayOrder: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

amenitySchema.virtual('id').get(function () {
  return this._id.toHexString();
});

amenitySchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Amenity', amenitySchema);
