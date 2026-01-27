const express = require('express');
const router = express.Router();
const multer = require('multer');
const {
  registerUser,
  registerAdmin,
  loginUser,
  sendOTP,
  verifyOTP,
  forgotPassword,
  resetPassword,
  getCurrentUser,
  getAllUsers,
  toggleUserActive,
  updateUserStatus,
  updateManager,
  deleteManager,
  updateSecurity,
  deleteSecurity,
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const { uploadToCloudinary } = require('../middleware/upload');
const { loginLimiter, otpLimiter, passwordResetLimiter } = require('../middleware/rateLimiter');

// Configure multer for memory storage (to upload to Cloudinary)
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  },
});

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
router.post(
  '/register',
  upload.fields([
    { name: 'profilePic', maxCount: 1 },
    { name: 'aadhaarFront', maxCount: 1 },
    { name: 'aadhaarBack', maxCount: 1 },
    { name: 'panCard', maxCount: 1 },
  ]),
  registerUser
);

// @route   POST /api/auth/register-admin
// @desc    Register a new admin
// @access  Public (can be protected later)
router.post('/register-admin', registerAdmin);

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', loginLimiter, loginUser);

// @route   POST /api/auth/send-otp
// @desc    Send OTP for email verification
// @access  Public
router.post('/send-otp', otpLimiter, sendOTP);

// @route   POST /api/auth/verify-otp
// @desc    Verify OTP
// @access  Public
router.post('/verify-otp', otpLimiter, verifyOTP);

// @route   POST /api/auth/forgot-password
// @desc    Send password reset OTP
// @access  Public
router.post('/forgot-password', passwordResetLimiter, forgotPassword);

// @route   POST /api/auth/reset-password
// @desc    Reset password
// @access  Public
router.post('/reset-password', passwordResetLimiter, resetPassword);

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', protect, getCurrentUser);

// @route   GET /api/auth/users
// @desc    Get all users
// @access  Public (should be protected in production)
router.get('/users', getAllUsers);

// @route   PUT /api/auth/users/:id/toggle-active
// @desc    Toggle user active status
// @access  Public (should be protected in production)
router.put('/users/:id/toggle-active', toggleUserActive);

// @route   PUT /api/auth/users/:id/status
// @desc    Approve or reject tenant
// @access  Public (should be protected in production)
router.put('/users/:id/status', updateUserStatus);

// @route   PUT /api/auth/managers/:id
// @desc    Update manager
// @access  Public (should be protected in production)
router.put(
  '/managers/:id',
  upload.fields([
    { name: 'profilePic', maxCount: 1 },
    { name: 'aadhaarFront', maxCount: 1 },
  ]),
  updateManager
);

// @route   DELETE /api/auth/managers/:id
// @desc    Delete manager
// @access  Public (should be protected in production)
router.delete('/managers/:id', deleteManager);

// @route   PUT /api/auth/security/:id
// @desc    Update security staff
// @access  Public (should be protected in production)
router.put(
  '/security/:id',
  upload.fields([
    { name: 'profilePic', maxCount: 1 },
    { name: 'aadhaarFront', maxCount: 1 },
  ]),
  updateSecurity
);

// @route   DELETE /api/auth/security/:id
// @desc    Delete security staff
// @access  Public (should be protected in production)
router.delete('/security/:id', deleteSecurity);

module.exports = router;

