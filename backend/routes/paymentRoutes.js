const express = require('express');
const router = express.Router();
const {
  getAllPayments,
  getPaymentsByUser,
  getPaymentById,
  getPaymentStats,
  assignPayment,
  createRazorpayOrder,
  completePayment,
  recordPayment,
} = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

// Must be before /:id
router.get('/my', protect, getPaymentsByUser);
router.get('/stats', protect, getPaymentStats);
router.post('/create-order', protect, createRazorpayOrder);

router.get('/', protect, getAllPayments);
router.post('/', protect, assignPayment);
router.post('/record', protect, recordPayment);

// Get one payment (owner or admin)
router.get('/:id', protect, getPaymentById);

// Complete payment after Razorpay (user)
router.patch('/:id/complete', protect, completePayment);

module.exports = router;
