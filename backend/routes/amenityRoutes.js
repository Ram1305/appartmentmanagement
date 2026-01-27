const express = require('express');
const router = express.Router();
const {
  getAmenities,
  createAmenity,
  updateAmenity,
  deleteAmenity,
} = require('../controllers/amenityController');
const { protect } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/requireAdmin');

// GET /api/amenities - any authenticated user; ?activeOnly=true for residents
router.get('/', protect, getAmenities);

// Admin-only write operations
router.post('/', protect, requireAdmin, createAmenity);
router.put('/:id', protect, requireAdmin, updateAmenity);
router.delete('/:id', protect, requireAdmin, deleteAmenity);

module.exports = router;
