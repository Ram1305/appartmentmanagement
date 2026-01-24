const Admin = require('../models/Admin');

const requireAdmin = async (req, res, next) => {
  try {
    const admin = await Admin.findById(req.userId);
    if (!admin) {
      return res.status(403).json({
        error: 'Not authorized. Admin access required.',
      });
    }
    req.adminId = admin._id;
    next();
  } catch (error) {
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

module.exports = { requireAdmin };
