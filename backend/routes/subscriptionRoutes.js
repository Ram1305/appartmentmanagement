const express = require('express');
const router = express.Router();
const {
  getPlans,
  createOrder,
  verifyPayment,
  getMySubscription,
  getAppActive,
} = require('../controllers/subscriptionController');
const { protect } = require('../middleware/auth');

// GET /api/subscription/plans - list active plans (public so app can show plans)
router.get('/plans', getPlans);

// GET /api/subscription/app-active - is any admin subscription active (for user/security)
router.get('/app-active', getAppActive);

// All below require auth only (no admin validation)
router.get('/my', protect, getMySubscription);
router.post('/create-order', protect, createOrder);
router.post('/verify', protect, verifyPayment);

module.exports = router;
