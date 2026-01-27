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

// Security/Admin routes (specific paths first so they are not matched by /:id)
router.post('/security', protect, createVisitorBySecurity);
router.get('/all/list', protect, getAllVisitors);
router.post('/verify-otp', protect, verifyVisitorOTP);

// User routes
router.post('/', protect, createVisitor);
router.get('/', protect, getUserVisitors);
router.get('/:id', protect, getVisitorById);

module.exports = router;
