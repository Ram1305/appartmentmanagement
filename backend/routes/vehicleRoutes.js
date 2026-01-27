const express = require('express');
const router = express.Router();
const { createVehicle, getVehiclesByUser } = require('../controllers/vehicleController');
const { protect } = require('../middleware/auth');
const { uploadSingleImage } = require('../middleware/upload');

router.get('/', protect, getVehiclesByUser);
router.post(
  '/',
  protect,
  uploadSingleImage('image'),
  createVehicle
);

module.exports = router;
