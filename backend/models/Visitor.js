const mongoose = require('mongoose');

const visitorSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Visitor name is required'],
      trim: true,
    },
    mobileNumber: {
      type: String,
      required: [true, 'Mobile number is required'],
      match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit mobile number'],
    },
    image: {
      type: String, // URL to image stored in cloudinary
    },
    category: {
      type: String,
      enum: ['relative', 'outsider'],
      required: [true, 'Visitor category is required'],
    },
    relativeType: {
      type: String,
      enum: ['father', 'mother', 'brother', 'sister', 'spouse', 'son', 'daughter', 'other'],
    },
    type: {
      type: String,
      enum: [
        'cabTaxi', 'family', 'deliveryBoy', 'guest', 'maid', 'electrician', 'plumber',
        'courier', 'maintenance', 'officialVisitor', 'emergency', 'other',
        'swiggy', 'zomato', 'zepto', 'amazon', 'delivery', 'service',
      ],
      required: [true, 'Visitor type is required'],
    },
    reasonForVisit: {
      type: String,
      trim: true,
    },
    vehicleNumber: {
      type: String,
      trim: true,
    },
    block: {
      type: String,
      required: [true, 'Block is required'],
    },
    homeNumber: {
      type: String,
      required: [true, 'Home number is required'],
    },
    visitTime: {
      type: Date,
      required: [true, 'Visit time is required'],
    },
    otp: {
      type: String,
      required: true,
    },
    qrCode: {
      type: String, // JSON string with visitor data
      required: true,
    },
    isRegistered: {
      type: Boolean,
      default: false,
    },
    registeredBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
visitorSchema.index({ block: 1, homeNumber: 1 });
visitorSchema.index({ visitTime: -1 });
visitorSchema.index({ registeredBy: 1 });

module.exports = mongoose.model('Visitor', visitorSchema);
