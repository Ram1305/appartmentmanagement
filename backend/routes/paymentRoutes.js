const express = require('express');
const router = express.Router();
const {
  getAllPayments,
  getPaymentsByUser,
  getPaymentById,
  getPaymentStats,
  assignPayment,
  updatePayment,
  deletePayment,
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

// /:id/complete must be before /:id
router.patch('/:id/complete', protect, completePayment);
router.get('/:id', protect, getPaymentById);
router.patch('/:id', protect, updatePayment);
router.delete('/:id', protect, deletePayment);

module.exports = router;
