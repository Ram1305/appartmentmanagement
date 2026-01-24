const Admin = require('../models/Admin');

const requireAdmin = async (req, res, next) => {
  try {
    // Check if userId exists (should be set by protect middleware)
    if (!req.userId) {
      return res.status(401).json({
        error: 'Not authorized. Please log in first.',
      });
    }

    const admin = await Admin.findById(req.userId);
    if (!admin) {
      console.error('Admin authorization failed:', {
        userId: req.userId,
        message: 'User ID not found in Admin collection. User may be logged in as a regular user, not an admin.',
      });
      return res.status(403).json({
        error: 'Not authorized. Admin access required. Please log in with admin credentials.',
      });
    }

    // Check if admin is active
    if (!admin.isActive) {
      return res.status(403).json({
        error: 'Admin account is inactive. Please contact support.',
      });
    }

    req.adminId = admin._id;
    next();
  } catch (error) {
    console.error('requireAdmin middleware error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

module.exports = { requireAdmin };
