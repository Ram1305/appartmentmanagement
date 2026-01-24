const express = require('express');
const router = express.Router();
const { getAds, createAd, deleteAd } = require('../controllers/adController');
const { protect } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/requireAdmin');
const { uploadSingleImage } = require('../middleware/upload');

router.get('/', protect, getAds);
router.post(
  '/',
  protect,
  requireAdmin,
  uploadSingleImage('image'),
  createAd
);
router.delete('/:id', protect, requireAdmin, deleteAd);

module.exports = router;
