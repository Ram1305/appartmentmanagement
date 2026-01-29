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
const { requireAdmin } = require('../middleware/requireAdmin');

// GET /api/subscription/plans - list active plans (public so app can show plans)
router.get('/plans', getPlans);

// GET /api/subscription/app-active - is any admin subscription active (for user/security)
router.get('/app-active', getAppActive);

// All below require auth
router.get('/my', protect, requireAdmin, getMySubscription);
router.post('/create-order', protect, requireAdmin, createOrder);
router.post('/verify', protect, requireAdmin, verifyPayment);

module.exports = router;
