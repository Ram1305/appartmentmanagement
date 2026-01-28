const express = require('express');
const router = express.Router();
const {
  createTicket,
  getTickets,
  getTicketById,
  getMessages,
  sendMessage,
  updateTicketStatus,
} = require('../controllers/supportController');
const { protect } = require('../middleware/auth');
const { uploadSingleImage } = require('../middleware/upload');

// All routes require auth only; admin/manager checks done inside support controller
router.post('/tickets', protect, createTicket);
router.get('/tickets', protect, getTickets);
router.get('/tickets/:id', protect, getTicketById);
router.get('/tickets/:id/messages', protect, getMessages);
router.post('/tickets/:id/messages', protect, uploadSingleImage('image'), sendMessage);
router.patch('/tickets/:id/status', protect, updateTicketStatus);

module.exports = router;
