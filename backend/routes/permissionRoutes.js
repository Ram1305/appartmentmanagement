const express = require('express');
const router = express.Router();
const {
  getPermissions,
  updatePermissions,
} = require('../controllers/permissionController');

// @route   GET /api/permissions/:userType
// @desc    Get permissions for user type
// @access  Public
router.get('/:userType', getPermissions);

// @route   PUT /api/permissions/:userType
// @desc    Update permissions
// @access  Public
router.put('/:userType', updatePermissions);

module.exports = router;

