const Vehicle = require('../models/Vehicle');
const { uploadToCloudinary } = require('../middleware/upload');

// @desc    Create vehicle
// @route   POST /api/vehicles
// @access  Private (User)
const createVehicle = async (req, res) => {
  try {
    const { vehicleType, vehicleNumber } = req.body;

    if (!vehicleType || !vehicleNumber) {
      return res.status(400).json({
        success: false,
        error: 'Vehicle type and vehicle number are required',
      });
    }

    const validTypes = ['twoWheeler', 'fourWheeler', 'other'];
    if (!validTypes.includes(vehicleType)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid vehicle type. Use twoWheeler, fourWheeler, or other',
      });
    }

    let imageUrl;
    if (req.file && req.file.buffer) {
      imageUrl = await uploadToCloudinary(
        req.file.buffer,
        'apartment_management/vehicles'
      );
    }

    const vehicle = await Vehicle.create({
      user: req.userId,
      vehicleType,
      vehicleNumber: vehicleNumber.trim(),
      image: imageUrl || undefined,
    });

    res.status(201).json({
      success: true,
      message: 'Vehicle created successfully',
      vehicle,
    });
  } catch (error) {
    console.error('Create vehicle error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get vehicles by current user
// @route   GET /api/vehicles
// @access  Private (User)
const getVehiclesByUser = async (req, res) => {
  try {
    const vehicles = await Vehicle.find({ user: req.userId }).sort({
      createdAt: -1,
    });

    res.json({
      success: true,
      count: vehicles.length,
      vehicles,
    });
  } catch (error) {
    console.error('Get vehicles error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete vehicle
// @route   DELETE /api/vehicles/:id
// @access  Private (User - own vehicle only)
const deleteVehicle = async (req, res) => {
  try {
    const vehicle = await Vehicle.findById(req.params.id);
    if (!vehicle) {
      return res.status(404).json({
        success: false,
        error: 'Vehicle not found',
      });
    }
    if (vehicle.user.toString() !== req.userId) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to delete this vehicle',
      });
    }
    await Vehicle.findByIdAndDelete(req.params.id);
    res.json({
      success: true,
      message: 'Vehicle deleted successfully',
    });
  } catch (error) {
    console.error('Delete vehicle error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  createVehicle,
  getVehiclesByUser,
  deleteVehicle,
};
