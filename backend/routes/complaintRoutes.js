const express = require('express');
const router = express.Router();
const {
  createComplaint,
  getComplaints,
  updateComplaintStatus,
} = require('../controllers/complaintController');
const { protect } = require('../middleware/auth');

router.post('/', protect, createComplaint);
router.get('/', protect, getComplaints);
router.patch('/:id/status', protect, updateComplaintStatus);

module.exports = router;
