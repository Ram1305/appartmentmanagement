const Permission = require('../models/Permission');

// @desc    Get permissions for user type
// @route   GET /api/permissions/:userType
// @access  Public
const getPermissions = async (req, res) => {
  try {
    const permission = await Permission.findOne({ userType: req.params.userType });

    if (!permission) {
      // Return default permissions if not found
      return res.json({
        success: true,
        permission: {
          userType: req.params.userType,
          permissions: {
            viewUsers: false,
            editUsers: false,
            deleteUsers: false,
            viewBlocks: false,
            editBlocks: false,
            deleteBlocks: false,
            viewPayments: false,
            managePayments: false,
            viewReports: false,
            manageNotices: false,
            approveTenants: false,
            setMaintenance: false,
          },
        },
      });
    }

    res.json({
      success: true,
      permission,
    });
  } catch (error) {
    console.error('Get permissions error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update permissions
// @route   PUT /api/permissions/:userType
// @access  Public
const updatePermissions = async (req, res) => {
  try {
    const { permissions } = req.body;

    let permission = await Permission.findOne({ userType: req.params.userType });

    if (!permission) {
      permission = await Permission.create({
        userType: req.params.userType,
        permissions,
      });
    } else {
      permission.permissions = { ...permission.permissions, ...permissions };
      await permission.save();
    }

    res.json({
      success: true,
      message: 'Permissions updated successfully',
      permission,
    });
  } catch (error) {
    console.error('Update permissions error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getPermissions,
  updatePermissions,
};

