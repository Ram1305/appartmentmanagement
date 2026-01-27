const Payment = require('../models/Payment');
const User = require('../models/User');
const Admin = require('../models/Admin');

// Helper: get amount for stats (totalAmount or amount)
const getPaymentAmount = (p) => (p.totalAmount != null ? p.totalAmount : p.amount) || 0;

// @desc    Get all payments (admin)
// @route   GET /api/payments
const getAllPayments = async (req, res) => {
  try {
    const { month, year, status } = req.query;

    let query = {};
    if (month) query.month = month;
    if (year) query.year = Number(year);
    if (status) query.status = status;

    const payments = await Payment.find(query)
      .populate('userId', 'name email mobileNumber block floor roomNumber')
      .sort({ year: -1, createdAt: -1 });

    res.json({
      success: true,
      count: payments.length,
      payments,
    });
  } catch (error) {
    console.error('Get payments error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get payments for current user (my payments)
// @route   GET /api/payments/my
const getPaymentsByUser = async (req, res) => {
  try {
    const userId = req.userId;
    const { month, year, status } = req.query;

    let query = { userId };
    if (month) query.month = month;
    if (year) query.year = Number(year);
    if (status) query.status = status;

    const payments = await Payment.find(query)
      .sort({ year: -1, createdAt: -1 });

    res.json({
      success: true,
      count: payments.length,
      payments,
    });
  } catch (error) {
    console.error('Get my payments error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get single payment by id
// @route   GET /api/payments/:id
const getPaymentById = async (req, res) => {
  try {
    const { id } = req.params;
    const payment = await Payment.findById(id).populate(
      'userId',
      'name email mobileNumber block floor roomNumber'
    );

    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }

    const ownerId = payment.userId && (payment.userId._id ? payment.userId._id.toString() : payment.userId.toString());
    if (ownerId !== req.userId) {
      const admin = await Admin.findById(req.userId);
      if (!admin || !admin.isActive) {
        return res.status(403).json({
          success: false,
          error: 'Not authorized to view this payment',
        });
      }
    }

    res.json({
      success: true,
      payment,
    });
  } catch (error) {
    console.error('Get payment by id error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get payment statistics
// @route   GET /api/payments/stats
const getPaymentStats = async (req, res) => {
  try {
    const { month, year } = req.query;

    let query = {};
    if (month) query.month = month;
    if (year) query.year = Number(year);

    const payments = await Payment.find(query);

    const stats = {
      total: payments.length,
      paid: payments.filter((p) => p.status === 'paid').length,
      pending: payments.filter((p) => p.status === 'pending').length,
      overdue: payments.filter((p) => p.status === 'overdue').length,
      totalAmount: payments.reduce((sum, p) => sum + getPaymentAmount(p), 0),
      paidAmount: payments
        .filter((p) => p.status === 'paid')
        .reduce((sum, p) => sum + getPaymentAmount(p), 0),
      pendingAmount: payments
        .filter((p) => p.status === 'pending')
        .reduce((sum, p) => sum + getPaymentAmount(p), 0),
    };

    res.json({
      success: true,
      stats,
    });
  } catch (error) {
    console.error('Get payment stats error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Assign payment to user (admin) – create pending payment with line items
// @route   POST /api/payments
const assignPayment = async (req, res) => {
  try {
    const { userId, month, year, lineItems } = req.body;

    if (!userId || !month || year == null) {
      return res.status(400).json({
        success: false,
        error: 'userId, month, and year are required',
      });
    }

    if (!Array.isArray(lineItems) || lineItems.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'At least one line item (type, amount) is required',
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    const validTypes = [
      'Maintenance',
      'Rent',
      'Parking',
      'Amenities usage',
      'Penalty',
      'Electricity',
      'Water',
    ];
    const items = lineItems.map((item) => {
      const type = item.type && validTypes.includes(item.type) ? item.type : validTypes[0];
      const amount = Number(item.amount);
      return { type, amount: isNaN(amount) ? 0 : Math.max(0, amount) };
    });

    const totalAmount = items.reduce((sum, item) => sum + item.amount, 0);
    if (totalAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Total amount must be greater than 0',
      });
    }

    // Prevent duplicate: one payment per user per month (upsert or reject)
    const existing = await Payment.findOne({
      userId,
      month: String(month),
      year: Number(year),
      status: 'pending',
    });
    if (existing) {
      return res.status(400).json({
        success: false,
        error: 'A pending payment already exists for this user and month. Update or delete it first.',
      });
    }

    const payment = await Payment.create({
      userId,
      month: String(month),
      year: Number(year),
      lineItems: items,
      totalAmount,
      amount: totalAmount,
      status: 'pending',
    });

    const populated = await Payment.findById(payment._id).populate(
      'userId',
      'name email mobileNumber block floor roomNumber'
    );

    res.status(201).json({
      success: true,
      message: 'Payment assigned successfully',
      payment: populated,
    });
  } catch (error) {
    console.error('Assign payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Create Razorpay order for a payment (user pays own)
// @route   POST /api/payments/create-order
const createRazorpayOrder = async (req, res) => {
  try {
    const userId = req.userId;
    const { paymentId } = req.body;

    if (!paymentId) {
      return res.status(400).json({
        success: false,
        error: 'paymentId is required',
      });
    }

    const payment = await Payment.findById(paymentId);
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }

    if (payment.userId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to pay this payment',
      });
    }

    if (payment.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Payment is not pending',
      });
    }

    const amount = payment.totalAmount != null ? payment.totalAmount : payment.amount;
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid payment amount',
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
      const order = await razorpay.orders.create({
        amount: amountPaise,
        currency: 'INR',
        receipt: paymentId,
      });
      orderId = order.id;
      payment.razorpayOrderId = order.id;
      await payment.save();
    } else {
      orderId = 'order_test_' + Date.now();
      payment.razorpayOrderId = orderId;
      await payment.save();
    }

    res.json({
      success: true,
      orderId,
      amount: amountPaise,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID || null,
    });
  } catch (error) {
    console.error('Create Razorpay order error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Mark payment as paid (after Razorpay success)
// @route   PATCH /api/payments/:id/complete
const completePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { transactionId, paymentMethod } = req.body;
    const userId = req.userId;

    const payment = await Payment.findById(id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }

    if (payment.userId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to complete this payment',
      });
    }

    if (payment.status === 'paid') {
      return res.json({
        success: true,
        message: 'Payment already completed',
        payment,
      });
    }

    payment.status = 'paid';
    payment.paymentDate = new Date();
    payment.transactionId = transactionId || payment.transactionId;
    payment.paymentMethod = paymentMethod || 'online';
    await payment.save();

    const populated = await Payment.findById(payment._id).populate(
      'userId',
      'name email mobileNumber block floor roomNumber'
    );

    res.json({
      success: true,
      message: 'Payment completed successfully',
      payment: populated,
    });
  } catch (error) {
    console.error('Complete payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update a payment (edit line items, month, year, or status)
// @route   PATCH /api/payments/:id
const updatePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { month, year, lineItems, status, paymentMethod, transactionId, notes } = req.body;

    const payment = await Payment.findById(id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }

    if (month !== undefined) payment.month = String(month);
    if (year !== undefined) payment.year = Number(year);
    if (notes !== undefined) payment.notes = notes;

    if (Array.isArray(lineItems) && lineItems.length > 0) {
      const validTypes = [
        'Maintenance', 'Rent', 'Parking', 'Amenities usage',
        'Penalty', 'Electricity', 'Water',
      ];
      const items = lineItems.map((item) => {
        const type = item.type && validTypes.includes(item.type) ? item.type : validTypes[0];
        const amount = Number(item.amount);
        return { type, amount: isNaN(amount) ? 0 : Math.max(0, amount) };
      });
      const totalAmount = items.reduce((sum, item) => sum + item.amount, 0);
      payment.lineItems = items;
      payment.totalAmount = totalAmount;
      payment.amount = totalAmount;
    }

    if (status !== undefined) {
      if (!['pending', 'paid', 'overdue'].includes(status)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid status. Use pending, paid, or overdue.',
        });
      }
      payment.status = status;
      if (status === 'paid') {
        payment.paymentDate = payment.paymentDate || new Date();
        if (paymentMethod) payment.paymentMethod = paymentMethod;
        if (transactionId !== undefined) payment.transactionId = transactionId;
      }
    } else if (paymentMethod !== undefined) payment.paymentMethod = paymentMethod;
    if (transactionId !== undefined) payment.transactionId = transactionId;

    await payment.save();

    const populated = await Payment.findById(payment._id).populate(
      'userId',
      'name email mobileNumber block floor roomNumber'
    );

    res.json({
      success: true,
      message: 'Payment updated successfully',
      payment: populated,
    });
  } catch (error) {
    console.error('Update payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete a payment
// @route   DELETE /api/payments/:id
const deletePayment = async (req, res) => {
  try {
    const { id } = req.params;
    const payment = await Payment.findById(id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }
    await Payment.findByIdAndDelete(id);
    res.json({
      success: true,
      message: 'Payment deleted successfully',
    });
  } catch (error) {
    console.error('Delete payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Record payment (legacy – manual record)
// @route   POST /api/payments/record
const recordPayment = async (req, res) => {
  try {
    const { userId, amount, month, year, paymentMethod, transactionId, notes } = req.body;

    if (!userId || amount == null || !month || year == null) {
      return res.status(400).json({
        success: false,
        error: 'userId, amount, month, and year are required',
      });
    }

    const numAmount = Number(amount);
    if (isNaN(numAmount) || numAmount < 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid amount is required',
      });
    }

    const payment = await Payment.create({
      userId,
      amount: numAmount,
      totalAmount: numAmount,
      month: String(month),
      year: Number(year),
      status: 'paid',
      paymentDate: new Date(),
      paymentMethod: paymentMethod || 'cash',
      transactionId,
      notes,
    });

    res.status(201).json({
      success: true,
      message: 'Payment recorded successfully',
      payment,
    });
  } catch (error) {
    console.error('Record payment error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
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
};
