const Admin = require('../models/Admin');

const requireAdmin = async (req, res, next) => {
  try {
    // Check if userId is set (should be set by protect middleware)
    if (!req.userId) {
      console.log('Admin authorization failed: No userId found in request');
      return res.status(401).json({
        success: false,
        error: 'Not authorized. Please login first.',
      });
    }

    // Check if user exists in Admin collection
    const admin = await Admin.findById(req.userId);
    
    if (!admin) {
      console.log('Admin authorization failed:', {
        userId: req.userId,
        message: 'User ID not found in Admin collection. User may be logged in as a regular user, not an admin.'
      });
      // CRITICAL: Return immediately and stop middleware chain
      return res.status(403).json({
        success: false,
        error: 'Not authorized. Only admins can perform this action.',
        message: 'User ID not found in Admin collection. User may be logged in as a regular user, not an admin.'
      });
    }

    // Check if admin is active
    if (!admin.isActive) {
      console.log('Admin authorization failed: Admin account is inactive', {
        userId: req.userId,
        adminId: admin._id
      });
      return res.status(403).json({
        success: false,
        error: 'Not authorized. Admin account is inactive.',
      });
    }

    // Set adminId for use in controllers - only reaches here if user is a valid active admin
    req.adminId = admin._id.toString();
    next();
  } catch (error) {
    console.error('Admin authorization error:', error);
    // Ensure error response is sent
    return res.status(500).json({
      success: false,
      error: error.message || 'Server error during admin authorization',
    });
  }
};

module.exports = { requireAdmin };
