const express = require('express');
const router = express.Router();
const { getAds, createAd, deleteAd } = require('../controllers/adController');
const { protect } = require('../middleware/auth');
const { uploadSingleImage } = require('../middleware/upload');

// Get ads - any authenticated user can view
router.get('/', protect, getAds);

// Create ad - any authenticated user can create ads
router.post(
  '/',
  protect,           // Must be authenticated
  uploadSingleImage('image'),
  createAd
);

// Delete ad - any authenticated user can delete ads
router.delete('/:id', protect, deleteAd);

module.exports = router;
