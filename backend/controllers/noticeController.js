const Notice = require('../models/Notice');

// @desc    Get all notices
// @route   GET /api/notices
// @access  Public
const getAllNotices = async (req, res) => {
  try {
    const { type, targetAudience, isActive } = req.query;

    let query = {};
    if (type) query.type = type;
    if (targetAudience) query.targetAudience = targetAudience;
    if (isActive !== undefined) query.isActive = isActive === 'true';

    const notices = await Notice.find(query)
      .populate('createdBy', 'name email')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: notices.length,
      notices,
    });
  } catch (error) {
    console.error('Get notices error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Create notice
// @route   POST /api/notices
// @access  Public
const createNotice = async (req, res) => {
  try {
    const { title, content, type, targetAudience, priority, expiryDate } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        error: 'Title and content are required',
      });
    }

    const notice = await Notice.create({
      title,
      content,
      type: type || 'general',
      targetAudience: targetAudience || 'all',
      priority: priority || 'medium',
      expiryDate: expiryDate ? new Date(expiryDate) : undefined,
      createdBy: req.userId,
      isActive: true,
    });

    res.status(201).json({
      success: true,
      message: 'Notice created successfully',
      notice,
    });
  } catch (error) {
    console.error('Create notice error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update notice
// @route   PUT /api/notices/:id
// @access  Public
const updateNotice = async (req, res) => {
  try {
    const notice = await Notice.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true,
      }
    );

    if (!notice) {
      return res.status(404).json({
        success: false,
        error: 'Notice not found',
      });
    }

    res.json({
      success: true,
      message: 'Notice updated successfully',
      notice,
    });
  } catch (error) {
    console.error('Update notice error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete notice
// @route   DELETE /api/notices/:id
// @access  Public
const deleteNotice = async (req, res) => {
  try {
    const notice = await Notice.findByIdAndDelete(req.params.id);

    if (!notice) {
      return res.status(404).json({
        success: false,
        error: 'Notice not found',
      });
    }

    res.json({
      success: true,
      message: 'Notice deleted successfully',
    });
  } catch (error) {
    console.error('Delete notice error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getAllNotices,
  createNotice,
  updateNotice,
  deleteNotice,
};

