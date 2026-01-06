const Maintenance = require('../models/Maintenance');

// @desc    Get all maintenance records
// @route   GET /api/maintenance/all
// @access  Public
const getAllMaintenance = async (req, res) => {
  try {
    const maintenanceList = await Maintenance.find().sort({ createdAt: -1 });

    res.json({
      success: true,
      maintenance: maintenanceList,
      count: maintenanceList.length,
    });
  } catch (error) {
    console.error('Get all maintenance error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get current maintenance amount
// @route   GET /api/maintenance
// @access  Public
const getMaintenance = async (req, res) => {
  try {
    const maintenance = await Maintenance.findOne({ isActive: true }).sort({ createdAt: -1 });

    if (!maintenance) {
      return res.json({
        success: true,
        maintenance: null,
        message: 'No maintenance amount set',
      });
    }

    res.json({
      success: true,
      maintenance,
    });
  } catch (error) {
    console.error('Get maintenance error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Set maintenance amount
// @route   POST /api/maintenance
// @access  Public
const setMaintenance = async (req, res) => {
  try {
    const { amount, month, year } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid maintenance amount is required',
      });
    }

    // Deactivate previous maintenance
    await Maintenance.updateMany({ isActive: true }, { isActive: false });

    // Create new maintenance
    const maintenance = await Maintenance.create({
      amount,
      month: month || new Date().toLocaleString('default', { month: 'long' }),
      year: year || new Date().getFullYear(),
      isActive: true,
    });

    res.status(201).json({
      success: true,
      message: 'Maintenance amount set successfully',
      maintenance,
    });
  } catch (error) {
    console.error('Set maintenance error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update maintenance amount
// @route   PUT /api/maintenance/:id
// @access  Public
const updateMaintenance = async (req, res) => {
  try {
    const { amount, month, year } = req.body;

    const maintenance = await Maintenance.findById(req.params.id);

    if (!maintenance) {
      return res.status(404).json({
        success: false,
        error: 'Maintenance not found',
      });
    }

    if (amount) maintenance.amount = amount;
    if (month) maintenance.month = month;
    if (year) maintenance.year = year;

    await maintenance.save();

    res.json({
      success: true,
      message: 'Maintenance updated successfully',
      maintenance,
    });
  } catch (error) {
    console.error('Update maintenance error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getAllMaintenance,
  getMaintenance,
  setMaintenance,
  updateMaintenance,
};

