const Ad = require('../models/Ad');
const { uploadToCloudinary } = require('../middleware/upload');

const getAds = async (req, res) => {
  try {
    const ads = await Ad.find({ isActive: true })
      .sort({ displayOrder: 1, createdAt: 1 });

    res.json({
      success: true,
      count: ads.length,
      ads,
    });
  } catch (error) {
    console.error('Get ads error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

const createAd = async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({
        success: false,
        error: 'Image file is required',
      });
    }

    const imageUrl = await uploadToCloudinary(
      req.file.buffer,
      'apartment_management/ads'
    );

    const displayOrder = req.body.displayOrder
      ? parseInt(req.body.displayOrder, 10)
      : 0;

    const ad = await Ad.create({
      image: imageUrl,
      displayOrder: isNaN(displayOrder) ? 0 : displayOrder,
      isActive: true,
      createdBy: req.userId, // Store the user ID who created the ad
    });

    res.status(201).json({
      success: true,
      message: 'Ad created successfully',
      ad,
    });
  } catch (error) {
    console.error('Create ad error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

const deleteAd = async (req, res) => {
  try {
    const ad = await Ad.findByIdAndDelete(req.params.id);

    if (!ad) {
      return res.status(404).json({
        success: false,
        error: 'Ad not found',
      });
    }

    res.json({
      success: true,
      message: 'Ad deleted successfully',
    });
  } catch (error) {
    console.error('Delete ad error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getAds,
  createAd,
  deleteAd,
};
