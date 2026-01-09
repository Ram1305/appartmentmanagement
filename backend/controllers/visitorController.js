const Visitor = require('../models/Visitor');
const User = require('../models/User');
const mongoose = require('mongoose');
const crypto = require('crypto');

// @desc    Create visitor
// @route   POST /api/visitors
// @access  Private (User)
const createVisitor = async (req, res) => {
  try {
    const {
      name,
      mobileNumber,
      category,
      relativeType,
      type,
      reasonForVisit,
      visitTime,
      image,
    } = req.body;

    // Validation
    if (!name || !mobileNumber || !category || !reasonForVisit || !visitTime) {
      return res.status(400).json({
        success: false,
        error: 'Name, mobile number, category, reason, and visit time are required',
      });
    }

    if (category === 'relative' && !relativeType) {
      return res.status(400).json({
        success: false,
        error: 'Relative type is required for relative visitors',
      });
    }

    if (category === 'outsider' && !type) {
      return res.status(400).json({
        success: false,
        error: 'Visitor type is required for outsider visitors',
      });
    }

    // Get user info for block and room
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    if (!user.block || !user.roomNumber) {
      return res.status(400).json({
        success: false,
        error: 'User must have block and room assigned',
      });
    }

    // Generate OTP (6 digits)
    const otp = crypto.randomInt(100000, 999999).toString();

    // Create visitor ID
    const visitorId = new mongoose.Types.ObjectId();

    // Generate QR code data (JSON string)
    const qrData = JSON.stringify({
      visitorId: visitorId.toString(),
      name,
      mobileNumber,
      block: user.block,
      homeNumber: user.roomNumber,
      visitTime: new Date(visitTime).toISOString(),
      otp,
    });

    // Create visitor
    const visitor = await Visitor.create({
      name,
      mobileNumber,
      category,
      relativeType: category === 'relative' ? relativeType : undefined,
      type: category === 'relative' ? 'guest' : type,
      reasonForVisit,
      image: image || undefined,
      block: user.block,
      homeNumber: user.roomNumber,
      visitTime: new Date(visitTime),
      otp,
      qrCode: qrData,
      registeredBy: req.userId,
      isRegistered: true,
    });

    res.status(201).json({
      success: true,
      message: 'Visitor created successfully',
      visitor,
    });
  } catch (error) {
    console.error('Create visitor error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get all visitors for a user
// @route   GET /api/visitors
// @access  Private (User)
const getUserVisitors = async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user || !user.block || !user.roomNumber) {
      return res.json({
        success: true,
        visitors: [],
      });
    }

    const visitors = await Visitor.find({
      block: user.block,
      homeNumber: user.roomNumber,
      registeredBy: req.userId,
    })
      .sort({ visitTime: -1 })
      .select('-__v');

    res.json({
      success: true,
      count: visitors.length,
      visitors,
    });
  } catch (error) {
    console.error('Get visitors error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get visitor by ID
// @route   GET /api/visitors/:id
// @access  Private (User)
const getVisitorById = async (req, res) => {
  try {
    const visitor = await Visitor.findById(req.params.id)
      .populate('registeredBy', 'name email mobileNumber')
      .select('-__v');

    if (!visitor) {
      return res.status(404).json({
        success: false,
        error: 'Visitor not found',
      });
    }

    // Check if visitor belongs to the user
    if (visitor.registeredBy._id.toString() !== req.userId) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to view this visitor',
      });
    }

    res.json({
      success: true,
      visitor,
    });
  } catch (error) {
    console.error('Get visitor error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get all visitors (for security/admin)
// @route   GET /api/visitors/all
// @access  Private (Security/Admin)
const getAllVisitors = async (req, res) => {
  try {
    const { block, homeNumber, date } = req.query;

    let query = {};
    if (block) query.block = block;
    if (homeNumber) query.homeNumber = homeNumber;
    if (date) {
      const startDate = new Date(date);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(date);
      endDate.setHours(23, 59, 59, 999);
      query.visitTime = { $gte: startDate, $lte: endDate };
    }

    const visitors = await Visitor.find(query)
      .populate('registeredBy', 'name email mobileNumber')
      .sort({ visitTime: -1 })
      .select('-__v');

    res.json({
      success: true,
      count: visitors.length,
      visitors,
    });
  } catch (error) {
    console.error('Get all visitors error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Verify visitor OTP
// @route   POST /api/visitors/verify-otp
// @access  Private (Security)
const verifyVisitorOTP = async (req, res) => {
  try {
    const { visitorId, otp } = req.body;

    if (!visitorId || !otp) {
      return res.status(400).json({
        success: false,
        error: 'Visitor ID and OTP are required',
      });
    }

    const visitor = await Visitor.findById(visitorId);

    if (!visitor) {
      return res.status(404).json({
        success: false,
        error: 'Visitor not found',
      });
    }

    if (visitor.otp !== otp) {
      return res.status(400).json({
        success: false,
        error: 'Invalid OTP',
      });
    }

    // Check if visit time is valid (within 24 hours)
    const now = new Date();
    const visitTime = new Date(visitor.visitTime);
    const hoursDiff = (now - visitTime) / (1000 * 60 * 60);

    if (hoursDiff > 24) {
      return res.status(400).json({
        success: false,
        error: 'Visitor pass has expired',
      });
    }

    res.json({
      success: true,
      message: 'OTP verified successfully',
      visitor: {
        id: visitor._id,
        name: visitor.name,
        block: visitor.block,
        homeNumber: visitor.homeNumber,
      },
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  createVisitor,
  getUserVisitors,
  getVisitorById,
  getAllVisitors,
  verifyVisitorOTP,
};
