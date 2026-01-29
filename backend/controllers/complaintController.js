const Complaint = require('../models/Complaint');
const User = require('../models/User');
const Admin = require('../models/Admin');
const Manager = require('../models/Manager');
const mongoose = require('mongoose');

/**
 * Resolve whether the caller is admin or user (resident).
 * @returns {'admin'|'user'|null}
 */
const getCallerType = async (req) => {
  if (!req.userId) return null;
  const admin = await Admin.findById(req.userId);
  if (admin) return 'admin';
  const user = await User.findById(req.userId);
  if (user) return 'user';
  const manager = await Manager.findById(req.userId);
  if (manager) return 'admin';
  return null;
};

/**
 * Normalize a complaint document (populated or lean) to API response shape.
 */
const toResponse = (c) => {
  const o = {
    id: c._id.toString(),
    userId: c.userId?._id?.toString() ?? c.userId?.toString(),
    type: c.type,
    description: c.description,
    status: c.status,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
    block: c.block ?? '',
    floor: c.floor ?? '',
    roomNumber: c.roomNumber ?? '',
  };
  if (c.userId && typeof c.userId === 'object') {
    o.userName = c.userId.name;
    if (o.block === '' && c.userId.block != null) o.block = c.userId.block;
    if (o.floor === '' && c.userId.floor != null) o.floor = c.userId.floor;
    if (o.roomNumber === '' && c.userId.roomNumber != null) o.roomNumber = c.userId.roomNumber;
  }
  return o;
};

// @desc    Create a complaint (resident only)
// @route   POST /api/complaints
// @access  Private (User only)
const createComplaint = async (req, res) => {
  try {
    const callerType = await getCallerType(req);
    if (callerType !== 'user') {
      return res.status(403).json({
        success: false,
        error: 'Only residents can create complaints.',
      });
    }

    const { type, description, block, floor, roomNumber } = req.body;
    if (!type || !description || !description.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Type and description are required.',
      });
    }

    const validTypes = ['plumbing', 'electrical', 'cleaning', 'maintenance', 'security', 'other'];
    if (!validTypes.includes(type.trim().toLowerCase())) {
      return res.status(400).json({
        success: false,
        error: 'Invalid type. Use: plumbing, electrical, cleaning, maintenance, security, other.',
      });
    }

    let finalBlock = block != null ? String(block).trim() : '';
    let finalFloor = floor != null ? String(floor).trim() : '';
    let finalRoom = roomNumber != null ? String(roomNumber).trim() : '';
    if (finalBlock === '' || finalFloor === '' || finalRoom === '') {
      const user = await User.findById(req.userId).select('block floor roomNumber').lean();
      if (user) {
        if (finalBlock === '' && user.block != null) finalBlock = String(user.block);
        if (finalFloor === '' && user.floor != null) finalFloor = String(user.floor);
        if (finalRoom === '' && user.roomNumber != null) finalRoom = String(user.roomNumber);
      }
    }

    const complaint = await Complaint.create({
      userId: req.userId,
      type: type.trim().toLowerCase(),
      description: description.trim(),
      block: finalBlock,
      floor: finalFloor,
      roomNumber: finalRoom,
      status: 'pending',
    });

    const populated = await Complaint.findById(complaint._id).populate('userId', 'name block floor roomNumber').lean();
    res.status(201).json({
      success: true,
      complaint: toResponse(populated),
    });
  } catch (error) {
    console.error('Create complaint error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get complaints (own for resident, all for admin with optional status filter)
// @route   GET /api/complaints
// @access  Private
const getComplaints = async (req, res) => {
  try {
    const callerType = await getCallerType(req);
    if (!callerType) {
      return res.status(403).json({
        success: false,
        error: 'Invalid session.',
      });
    }

    let query = {};
    if (callerType === 'user') {
      query.userId = req.userId;
    } else {
      const statusParam = req.query.status;
      if (statusParam === 'completed') {
        query.status = { $in: ['completed', 'cancelled'] };
      } else if (statusParam === 'pending' || !statusParam) {
        query.status = { $in: ['pending', 'approved'] };
      }
    }

    const complaints = await Complaint.find(query)
      .populate('userId', 'name block floor roomNumber')
      .sort({ createdAt: -1 })
      .lean();

    const list = complaints.map((c) => toResponse(c));
    res.json({
      success: true,
      complaints: list,
    });
  } catch (error) {
    console.error('Get complaints error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update complaint status (admin/manager only)
// @route   PATCH /api/complaints/:id/status
// @access  Private (Admin/Manager only)
const updateComplaintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, error: 'Invalid complaint id.' });
    }
    const validStatuses = ['pending', 'approved', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Use: pending, approved, completed, or cancelled.',
      });
    }

    const callerType = await getCallerType(req);
    if (callerType !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can update complaint status.',
      });
    }

    const complaint = await Complaint.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    ).populate('userId', 'name block floor roomNumber').lean();

    if (!complaint) {
      return res.status(404).json({ success: false, error: 'Complaint not found.' });
    }

    res.json({
      success: true,
      complaint: toResponse(complaint),
    });
  } catch (error) {
    console.error('Update complaint status error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  createComplaint,
  getComplaints,
  updateComplaintStatus,
};
