const express = require('express');
const router = express.Router();
const {
  getAllMaintenance,
  getMaintenance,
  setMaintenance,
  updateMaintenance,
} = require('../controllers/maintenanceController');

// @route   GET /api/maintenance/all
// @desc    Get all maintenance records
// @access  Public
router.get('/all', getAllMaintenance);

// @route   GET /api/maintenance
// @desc    Get current maintenance amount
// @access  Public
router.get('/', getMaintenance);

// @route   POST /api/maintenance
// @desc    Set maintenance amount
// @access  Public
router.post('/', setMaintenance);

// @route   PUT /api/maintenance/:id
// @desc    Update maintenance amount
// @access  Public
router.put('/:id', updateMaintenance);

module.exports = router;

