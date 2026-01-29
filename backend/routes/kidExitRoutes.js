const express = require('express');
const router = express.Router();
const {
  createKidExit,
  getKidExits,
  acknowledgeKidExit,
} = require('../controllers/kidExitController');
const { protect } = require('../middleware/auth');

router.post('/', protect, createKidExit);
router.get('/', protect, getKidExits);
router.patch('/:id/acknowledge', protect, acknowledgeKidExit);

module.exports = router;
