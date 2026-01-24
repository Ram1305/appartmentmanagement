const express = require('express');
const router = express.Router();
const { getAds, createAd, deleteAd } = require('../controllers/adController');
const { protect } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/requireAdmin');
const { uploadSingleImage } = require('../middleware/upload');

// Get ads - any authenticated user can view
router.get('/', protect, getAds);

// Create ad - ONLY ADMINS can create ads
// Middleware order: protect (auth) -> requireAdmin (blocks non-admins) -> uploadSingleImage -> createAd
router.post(
  '/',
  protect,           // Step 1: Must be authenticated
  requireAdmin,      // Step 2: Must be admin (BLOCKS non-admins here)
  uploadSingleImage('image'), // Step 3: Only reached if admin
  createAd          // Step 4: Only reached if admin
);

// Delete ad - ONLY ADMINS can delete ads
router.delete('/:id', protect, requireAdmin, deleteAd);

module.exports = router;
