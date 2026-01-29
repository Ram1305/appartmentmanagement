const express = require('express');
const router = express.Router();
const { createVehicle, getVehiclesByUser, deleteVehicle } = require('../controllers/vehicleController');
const { protect } = require('../middleware/auth');
const { uploadSingleImage } = require('../middleware/upload');

router.get('/', protect, getVehiclesByUser);
router.post(
  '/',
  protect,
  uploadSingleImage('image'),
  createVehicle
);
router.delete('/:id', protect, deleteVehicle);

module.exports = router;
