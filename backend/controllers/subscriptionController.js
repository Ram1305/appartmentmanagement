const crypto = require('crypto');
const Admin = require('../models/Admin');
const SubscriptionPlan = require('../models/SubscriptionPlan');

// In-memory store for pending subscription orders: orderId -> { planId, adminId }
// Cleared after verify or after 1 hour (optional cleanup could be added)
const pendingSubscriptionOrders = new Map();

const getDaysLeft = (subscriptionEndsAt) => {
  if (!subscriptionEndsAt) return 0;
  const now = new Date();
  const end = new Date(subscriptionEndsAt);
  if (end <= now) return 0;
  return Math.ceil((end - now) / (24 * 60 * 60 * 1000));
};

const defaultPlans = [
  { name: 'Basic', daysValidity: 30, amount: 999, description: '1 month validity', displayOrder: 1, color: '#E3F2FD' },
  { name: 'Standard', daysValidity: 90, amount: 2499, description: '3 months validity', displayOrder: 2, color: '#E8F5E9' },
  { name: 'Premium', daysValidity: 365, amount: 8999, description: '1 year validity', displayOrder: 3, color: '#FFF8E1' },
];

// @desc    Get list of active subscription plans; seeds default plans if none exist
// @route   GET /api/subscription/plans
const getPlans = async (req, res) => {
  try {
    const count = await SubscriptionPlan.countDocuments();
    if (count === 0) {
      await SubscriptionPlan.insertMany(defaultPlans);
      console.log('[Subscription] Seeded', defaultPlans.length, 'plans.');
    }
    const plans = await SubscriptionPlan.find({ isActive: true })
      .sort({ displayOrder: 1, createdAt: 1 });
    res.json({
      success: true,
      plans,
    });
  } catch (error) {
    console.error('Get subscription plans error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get all subscription plans (history) - admin only, includes inactive
// @route   GET /api/subscription/plans/history
const getPlansHistory = async (req, res) => {
  try {
    const count = await SubscriptionPlan.countDocuments();
    if (count === 0) {
      return res.json({ success: true, plans: [] });
    }
    const plans = await SubscriptionPlan.find({})
      .sort({ displayOrder: 1, createdAt: -1 });
    res.json({
      success: true,
      plans,
    });
  } catch (error) {
    console.error('Get subscription plans history error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Create Razorpay order for subscription (admin only)
// @route   POST /api/subscription/create-order
const createOrder = async (req, res) => {
  try {
    const adminId = req.userId;
    const { planId } = req.body;

    if (!planId) {
      return res.status(400).json({
        success: false,
        error: 'planId is required',
      });
    }

    const plan = await SubscriptionPlan.findById(planId);
    if (!plan || !plan.isActive) {
      return res.status(404).json({
        success: false,
        error: 'Plan not found or inactive',
      });
    }

    const amount = plan.amount;
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid plan amount',
      });
    }

    const amountPaise = Math.round(amount * 100);
    let orderId;

    if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
      const Razorpay = require('razorpay');
      const razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
      });
      // Razorpay receipt must be <= 40 chars; planId/adminId are 24-char ObjectIds
      const planStr = String(planId).slice(-12);
      const adminStr = String(adminId).slice(-12);
      const receipt = `sub_${planStr}_${adminStr}`.slice(0, 40);
      const order = await razorpay.orders.create({
        amount: amountPaise,
        currency: 'INR',
        receipt,
      });
      orderId = order.id;
    } else {
      orderId = 'order_sub_test_' + Date.now();
    }

    pendingSubscriptionOrders.set(orderId, { planId: plan._id.toString(), adminId });
    // Optional: remove after 1 hour
    setTimeout(() => {
      pendingSubscriptionOrders.delete(orderId);
    }, 60 * 60 * 1000);

    res.json({
      success: true,
      orderId,
      amount: amountPaise,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID || null,
    });
  } catch (error) {
    console.error('Create subscription order error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Verify Razorpay payment and add subscription days to admin (admin only)
// @route   POST /api/subscription/verify
const verifyPayment = async (req, res) => {
  try {
    const adminId = req.userId;
    const { orderId, razorpayPaymentId, signature } = req.body;

    if (!orderId || !razorpayPaymentId || !signature) {
      return res.status(400).json({
        success: false,
        error: 'orderId, razorpayPaymentId and signature are required',
      });
    }

    const pending = pendingSubscriptionOrders.get(orderId);
    if (!pending || pending.adminId !== adminId) {
      return res.status(400).json({
        success: false,
        error: 'Invalid or expired order',
      });
    }

    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (keySecret && signature) {
      const expectedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(orderId + '|' + razorpayPaymentId)
        .digest('hex');
      if (expectedSignature !== signature) {
        pendingSubscriptionOrders.delete(orderId);
        return res.status(400).json({
          success: false,
          error: 'Payment signature verification failed',
        });
      }
    } else if (keySecret && !signature) {
      pendingSubscriptionOrders.delete(orderId);
      return res.status(400).json({
        success: false,
        error: 'Signature required for verification',
      });
    }

    const plan = await SubscriptionPlan.findById(pending.planId);
    if (!plan) {
      pendingSubscriptionOrders.delete(orderId);
      return res.status(404).json({
        success: false,
        error: 'Plan not found',
      });
    }

    const admin = await Admin.findById(adminId);
    if (!admin) {
      pendingSubscriptionOrders.delete(orderId);
      return res.status(404).json({
        success: false,
        error: 'Admin not found',
      });
    }

    const now = new Date();
    let newEndsAt = new Date(now.getTime() + plan.daysValidity * 24 * 60 * 60 * 1000);
    if (admin.subscriptionEndsAt && new Date(admin.subscriptionEndsAt) > now) {
      newEndsAt = new Date(new Date(admin.subscriptionEndsAt).getTime() + plan.daysValidity * 24 * 60 * 60 * 1000);
    }

    admin.subscriptionStatus = true;
    admin.subscriptionEndsAt = newEndsAt;
    admin.subscriptionPlanId = plan._id;
    await admin.save();

    pendingSubscriptionOrders.delete(orderId);

    const daysLeft = getDaysLeft(admin.subscriptionEndsAt);

    res.json({
      success: true,
      message: 'Subscription updated successfully',
      subscriptionStatus: true,
      subscriptionEndsAt: admin.subscriptionEndsAt,
      daysLeft,
    });
  } catch (error) {
    console.error('Verify subscription payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get current admin's subscription (admin only)
// @route   GET /api/subscription/my
const getMySubscription = async (req, res) => {
  try {
    const admin = await Admin.findById(req.userId)
      .select('subscriptionStatus subscriptionEndsAt subscriptionPlanId')
      .populate('subscriptionPlanId', 'name description daysValidity');

    if (!admin) {
      return res.status(404).json({
        success: false,
        error: 'Admin not found',
      });
    }

    const daysLeft = getDaysLeft(admin.subscriptionEndsAt);
    const subscriptionActive = !!(admin.subscriptionStatus && admin.subscriptionEndsAt && new Date(admin.subscriptionEndsAt) > new Date());

    res.json({
      success: true,
      subscriptionStatus: subscriptionActive,
      subscriptionEndsAt: admin.subscriptionEndsAt,
      daysLeft,
      plan: admin.subscriptionPlanId || null,
    });
  } catch (error) {
    console.error('Get my subscription error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Check if app is active (any admin has valid subscription) - for user/security
// @route   GET /api/subscription/app-active
const getAppActive = async (req, res) => {
  try {
    const now = new Date();
    const activeAdmin = await Admin.findOne({
      subscriptionStatus: true,
      subscriptionEndsAt: { $gt: now },
      isActive: true,
    });

    res.json({
      success: true,
      active: !!activeAdmin,
    });
  } catch (error) {
    console.error('Get app active error:', error);
    res.status(500).json({
      success: false,
      active: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getPlans,
  getPlansHistory,
  createOrder,
  verifyPayment,
  getMySubscription,
  getAppActive,
};
