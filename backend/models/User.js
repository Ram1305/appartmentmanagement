const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    username: {
      type: String,
      required: [true, 'Username is required'],
      unique: true,
      trim: true,
      lowercase: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      trim: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false, // Don't return password by default
    },
    mobileNumber: {
      type: String,
      required: [true, 'Mobile number is required'],
      match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit mobile number'],
    },
    secondaryMobileNumber: {
      type: String,
      match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit mobile number'],
    },
    gender: {
      type: String,
      enum: ['male', 'female', 'other'],
    },
    userType: {
      type: String,
      default: 'user',
      immutable: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    profilePic: {
      type: String, // Cloudinary URL
    },
    address: {
      type: String,
    },
    aadhaarCard: {
      type: String,
      // ID Card number - flexible validation for international use
      match: [/^[A-Z0-9]{5,20}$/i, 'ID card number must be 5-20 alphanumeric characters'],
    },
    aadhaarCardFrontImage: {
      type: String, // Cloudinary URL
    },
    aadhaarCardBackImage: {
      type: String, // Cloudinary URL
    },
    panCard: {
      type: String,
      match: [/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/, 'Please enter a valid PAN number'],
    },
    panCardImage: {
      type: String, // Cloudinary URL
    },
    familyType: {
      type: String,
      enum: ['family', 'bachelor'],
    },
    totalOccupants: {
      type: Number,
      min: 1,
    },
    block: {
      type: String,
    },
    floor: {
      type: String,
    },
    roomNumber: {
      type: String,
    },
    otp: {
      type: String,
      select: false,
    },
    otpExpiry: {
      type: Date,
      select: false,
    },
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpiry: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Generate OTP
userSchema.methods.generateOTP = function () {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  this.otp = otp;
  this.otpExpiry = Date.now() + 10 * 60 * 1000; // 10 minutes
  return otp;
};

// Verify OTP
userSchema.methods.verifyOTP = function (enteredOTP) {
  if (this.otp !== enteredOTP) {
    return false;
  }
  if (this.otpExpiry < Date.now()) {
    return false;
  }
  return true;
};

module.exports = mongoose.model('User', userSchema);

