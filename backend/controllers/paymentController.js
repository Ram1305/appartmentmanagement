const Payment = require('../models/Payment');
const User = require('../models/User');

// @desc    Get all payments
// @route   GET /api/payments
// @access  Public
const getAllPayments = async (req, res) => {
  try {
    const { month, year, status } = req.query;

    let query = {};
    if (month) query.month = month;
    if (year) query.year = year;
    if (status) query.status = status;

    const payments = await Payment.find(query)
      .populate('userId', 'name email mobileNumber block floor roomNumber')
      .sort({ createdAt: -1 });

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

// @desc    Get payment statistics
// @route   GET /api/payments/stats
// @access  Public
const getPaymentStats = async (req, res) => {
  try {
    const { month, year } = req.query;

    let query = {};
    if (month) query.month = month;
    if (year) query.year = year;

    const payments = await Payment.find(query);

    const stats = {
      total: payments.length,
      paid: payments.filter((p) => p.status === 'paid').length,
      pending: payments.filter((p) => p.status === 'pending').length,
      overdue: payments.filter((p) => p.status === 'overdue').length,
      totalAmount: payments.reduce((sum, p) => sum + p.amount, 0),
      paidAmount: payments
        .filter((p) => p.status === 'paid')
        .reduce((sum, p) => sum + p.amount, 0),
      pendingAmount: payments
        .filter((p) => p.status === 'pending')
        .reduce((sum, p) => sum + p.amount, 0),
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

// @desc    Record payment
// @route   POST /api/payments
// @access  Public
const recordPayment = async (req, res) => {
  try {
    const { userId, amount, month, year, paymentMethod, transactionId, notes } = req.body;

    if (!userId || !amount || !month || !year) {
      return res.status(400).json({
        success: false,
        error: 'User ID, amount, month, and year are required',
      });
    }

    const payment = await Payment.create({
      userId,
      amount,
      month,
      year,
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
  getPaymentStats,
  recordPayment,
};

