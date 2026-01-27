const Amenity = require('../models/Amenity');
const mongoose = require('mongoose');

const getAmenities = async (req, res) => {
  try {
    const activeOnly = req.query.activeOnly === 'true';
    const filter = activeOnly ? { isEnabled: true } : {};
    const amenities = await Amenity.find(filter).sort({
      displayOrder: 1,
      createdAt: 1,
    });

    res.json({
      success: true,
      count: amenities.length,
      amenities,
    });
  } catch (error) {
    console.error('Get amenities error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

const createAmenity = async (req, res) => {
  try {
    const { name, displayOrder } = req.body;
    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Amenity name is required',
      });
    }

    const order = displayOrder != null ? parseInt(displayOrder, 10) : 0;
    const amenity = await Amenity.create({
      name: name.trim(),
      isEnabled: true,
      displayOrder: isNaN(order) ? 0 : order,
    });

    res.status(201).json({
      success: true,
      message: 'Amenity created successfully',
      amenity,
    });
  } catch (error) {
    console.error('Create amenity error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

const updateAmenity = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid amenity id',
      });
    }

    const { name, isEnabled, displayOrder } = req.body;
    const update = {};
    if (typeof name === 'string') update.name = name.trim();
    if (typeof isEnabled === 'boolean') update.isEnabled = isEnabled;
    if (displayOrder != null) {
      const order = parseInt(displayOrder, 10);
      if (!isNaN(order)) update.displayOrder = order;
    }

    const amenity = await Amenity.findByIdAndUpdate(
      id,
      { $set: update },
      { new: true, runValidators: true }
    );

    if (!amenity) {
      return res.status(404).json({
        success: false,
        error: 'Amenity not found',
      });
    }

    res.json({
      success: true,
      message: 'Amenity updated successfully',
      amenity,
    });
  } catch (error) {
    console.error('Update amenity error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

const deleteAmenity = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid amenity id',
      });
    }

    const amenity = await Amenity.findByIdAndDelete(id);

    if (!amenity) {
      return res.status(404).json({
        success: false,
        error: 'Amenity not found',
      });
    }

    res.json({
      success: true,
      message: 'Amenity deleted successfully',
    });
  } catch (error) {
    console.error('Delete amenity error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getAmenities,
  createAmenity,
  updateAmenity,
  deleteAmenity,
};
