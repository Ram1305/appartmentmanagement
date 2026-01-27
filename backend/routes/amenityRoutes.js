const express = require('express');
const router = express.Router();
const {
  getAmenities,
  createAmenity,
  updateAmenity,
  deleteAmenity,
} = require('../controllers/amenityController');
const { protect } = require('../middleware/auth');

// All routes require authentication
router.get('/', protect, getAmenities);
router.post('/', protect, createAmenity);
router.put('/:id', protect, updateAmenity);
router.delete('/:id', protect, deleteAmenity);

module.exports = router;
