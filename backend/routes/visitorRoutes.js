const express = require('express');
const router = express.Router();
const {
  createVisitor,
  createVisitorBySecurity,
  getUserVisitors,
  getVisitorById,
  getAllVisitors,
  verifyVisitorOTP,
} = require('../controllers/visitorController');
const { protect } = require('../middleware/auth');

// User routes
router.post('/', protect, createVisitor);
router.get('/', protect, getUserVisitors);
router.get('/:id', protect, getVisitorById);

// Security/Admin routes
router.post('/security', protect, createVisitorBySecurity);
router.get('/all/list', protect, getAllVisitors);
router.post('/verify-otp', protect, verifyVisitorOTP);

module.exports = router;
