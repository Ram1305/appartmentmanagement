const express = require('express');
const router = express.Router();
const {
  getAllPayments,
  getPaymentStats,
  recordPayment,
} = require('../controllers/paymentController');

// @route   GET /api/payments
// @desc    Get all payments
// @access  Public
router.get('/', getAllPayments);

// @route   GET /api/payments/stats
// @desc    Get payment statistics
// @access  Public
router.get('/stats', getPaymentStats);

// @route   POST /api/payments
// @desc    Record payment
// @access  Public
router.post('/', recordPayment);

module.exports = router;

