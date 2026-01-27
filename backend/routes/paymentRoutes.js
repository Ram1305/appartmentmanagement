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
const { requireAdmin } = require('../middleware/requireAdmin');

// Must be before /:id
router.get('/my', protect, getPaymentsByUser);
router.get('/stats', protect, requireAdmin, getPaymentStats);
router.post('/create-order', protect, createRazorpayOrder);

// Admin: list all payments
router.get('/', protect, requireAdmin, getAllPayments);

// Assign payment (admin)
router.post('/', protect, requireAdmin, assignPayment);

// Manual record (admin)
router.post('/record', protect, requireAdmin, recordPayment);

// Get one payment (owner or admin)
router.get('/:id', protect, getPaymentById);

// Complete payment after Razorpay (user)
router.patch('/:id/complete', protect, completePayment);

module.exports = router;
