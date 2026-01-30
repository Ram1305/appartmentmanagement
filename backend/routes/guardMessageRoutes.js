const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getConversations,
  getMessages,
  sendMessage,
  markAsRead,
  markConversationAsRead,
  getUnreadCount,
  getSecurityList,
  getTenantList,
  getOrCreateConversation,
} = require('../controllers/guardMessageController');

// All routes require authentication
router.use(protect);

// Get all conversations for logged-in user
router.get('/conversations', getConversations);

// Get messages in a conversation
router.get('/conversations/:conversationId', getMessages);

// Mark all messages in conversation as read
router.put('/conversations/:conversationId/read', markConversationAsRead);

// Get or create a conversation with recipient
router.post('/conversation', getOrCreateConversation);

// Send a message
router.post('/send', sendMessage);

// Mark a single message as read
router.put('/:messageId/read', markAsRead);

// Get total unread count
router.get('/unread-count', getUnreadCount);

// Get list of security guards (for tenants)
router.get('/security-list', getSecurityList);

// Get list of tenants (for security)
router.get('/tenant-list', getTenantList);

module.exports = router;
