const express = require('express');
const router = express.Router();
const {
  getAllNotices,
  createNotice,
  updateNotice,
  deleteNotice,
} = require('../controllers/noticeController');

// @route   GET /api/notices
// @desc    Get all notices
// @access  Public
router.get('/', getAllNotices);

// @route   POST /api/notices
// @desc    Create notice
// @access  Public
router.post('/', createNotice);

// @route   PUT /api/notices/:id
// @desc    Update notice
// @access  Public
router.put('/:id', updateNotice);

// @route   DELETE /api/notices/:id
// @desc    Delete notice
// @access  Public
router.delete('/:id', deleteNotice);

module.exports = router;

