const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
    },
    vehicleType: {
      type: String,
      enum: ['twoWheeler', 'fourWheeler', 'other'],
      required: [true, 'Vehicle type is required'],
    },
    vehicleNumber: {
      type: String,
      required: [true, 'Vehicle number is required'],
      trim: true,
    },
    image: {
      type: String, // Cloudinary URL
    },
  },
  {
    timestamps: true,
  }
);

vehicleSchema.index({ user: 1 });

module.exports = mongoose.model('Vehicle', vehicleSchema);
