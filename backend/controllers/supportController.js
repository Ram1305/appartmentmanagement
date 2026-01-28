const Ticket = require('../models/Ticket');
const SupportMessage = require('../models/SupportMessage');
const User = require('../models/User');
const Admin = require('../models/Admin');
const Manager = require('../models/Manager');
const { uploadToCloudinary } = require('../middleware/upload');
const mongoose = require('mongoose');

/**
 * Resolve whether the caller is admin or user (resident).
 * Admins can be in Admin collection or User collection with userType 'admin'.
 * @returns {'admin'|'user'|null}
 */
const getCallerType = async (req) => {
  if (!req.userId) return null;
  const admin = await Admin.findById(req.userId);
  if (admin) return 'admin';
  const user = await User.findById(req.userId);
  if (user) {
    // User collection can contain admins (e.g. default admin from initAdmin script)
    if (user.userType === 'admin') return 'admin';
    return 'user';
  }
  const manager = await Manager.findById(req.userId);
  if (manager) return 'admin'; // managers see all tickets like admin
  return null;
};

// @desc    Create a support ticket
// @route   POST /api/support/tickets
// @access  Private (User only)
const createTicket = async (req, res) => {
  try {
    const callerType = await getCallerType(req);
    if (callerType !== 'user') {
      return res.status(403).json({
        success: false,
        error: 'Only residents can create support tickets.',
      });
    }

    const { issueType, description } = req.body;
    if (!issueType || !description || !description.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Issue type and description are required.',
      });
    }

    const ticket = await Ticket.create({
      userId: req.userId,
      issueType: issueType.trim(),
      description: description.trim(),
      status: 'open',
    });

    const populated = await Ticket.findById(ticket._id).populate('userId', 'name block floor roomNumber');
    res.status(201).json({
      success: true,
      ticket: populated,
    });
  } catch (error) {
    console.error('Create ticket error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get tickets (own for user, all for admin)
// @route   GET /api/support/tickets
// @access  Private
const getTickets = async (req, res) => {
  try {
    const callerType = await getCallerType(req);
    if (!callerType) {
      return res.status(403).json({
        success: false,
        error: 'Invalid session.',
      });
    }

    let query = {};
    if (callerType === 'user') {
      query.userId = req.userId;
    }

    const tickets = await Ticket.find(query)
      .populate('userId', 'name block floor roomNumber')
      .sort({ createdAt: -1 })
      .lean();

    // Normalize for response: flatten userId to user object for admin, or leave as id for user
    const list = tickets.map((t) => {
      const o = {
        id: t._id.toString(),
        userId: t.userId?._id?.toString() ?? t.userId?.toString(),
        issueType: t.issueType,
        description: t.description,
        status: t.status,
        createdAt: t.createdAt,
      };
      if (t.userId && typeof t.userId === 'object') {
        o.userName = t.userId.name;
        o.block = t.userId.block;
        o.floor = t.userId.floor;
        o.roomNumber = t.userId.roomNumber;
      }
      return o;
    });

    res.json({
      success: true,
      tickets: list,
    });
  } catch (error) {
    console.error('Get tickets error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get single ticket by id
// @route   GET /api/support/tickets/:id
// @access  Private (own ticket for user, any for admin)
const getTicketById = async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, error: 'Invalid ticket id.' });
    }

    const callerType = await getCallerType(req);
    if (!callerType) {
      return res.status(403).json({ success: false, error: 'Invalid session.' });
    }

    const ticket = await Ticket.findById(id).populate('userId', 'name block floor roomNumber').lean();
    if (!ticket) {
      return res.status(404).json({ success: false, error: 'Ticket not found.' });
    }

    const userIdStr = ticket.userId?._id?.toString() ?? ticket.userId?.toString();
    if (callerType === 'user' && userIdStr !== req.userId) {
      return res.status(403).json({ success: false, error: 'Not allowed to access this ticket.' });
    }

    const out = {
      id: ticket._id.toString(),
      userId: userIdStr,
      issueType: ticket.issueType,
      description: ticket.description,
      status: ticket.status,
      createdAt: ticket.createdAt,
    };
    if (ticket.userId && typeof ticket.userId === 'object') {
      out.userName = ticket.userId.name;
      out.block = ticket.userId.block;
      out.floor = ticket.userId.floor;
      out.roomNumber = ticket.userId.roomNumber;
    }
    res.json({ success: true, ticket: out });
  } catch (error) {
    console.error('Get ticket by id error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get messages for a ticket
// @route   GET /api/support/tickets/:id/messages
// @access  Private (own ticket for user, any for admin)
const getMessages = async (req, res) => {
  try {
    const { id: ticketId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(ticketId)) {
      return res.status(400).json({ success: false, error: 'Invalid ticket id.' });
    }

    const callerType = await getCallerType(req);
    if (!callerType) {
      return res.status(403).json({ success: false, error: 'Invalid session.' });
    }

    const ticket = await Ticket.findById(ticketId).lean();
    if (!ticket) {
      return res.status(404).json({ success: false, error: 'Ticket not found.' });
    }

    const ticketUserId = ticket.userId?.toString();
    if (callerType === 'user' && ticketUserId !== req.userId) {
      return res.status(403).json({ success: false, error: 'Not allowed to access this ticket.' });
    }

    const messages = await SupportMessage.find({ ticketId })
      .sort({ createdAt: 1 })
      .lean();

    const list = messages.map((m) => ({
      id: m._id.toString(),
      senderType: m.senderType,
      message: m.message || null,
      imageUrl: m.imageUrl || null,
      createdAt: m.createdAt,
    }));

    res.json({ success: true, messages: list });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Send a message on a ticket (optional text and/or image)
// @route   POST /api/support/tickets/:id/messages
// @access  Private (multer may attach req.file for 'image')
const sendMessage = async (req, res) => {
  try {
    const { id: ticketId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(ticketId)) {
      return res.status(400).json({ success: false, error: 'Invalid ticket id.' });
    }

    const callerType = await getCallerType(req);
    if (!callerType) {
      return res.status(403).json({ success: false, error: 'Invalid session.' });
    }

    const ticket = await Ticket.findById(ticketId);
    if (!ticket) {
      return res.status(404).json({ success: false, error: 'Ticket not found.' });
    }

    const ticketUserId = ticket.userId.toString();
    if (callerType === 'user' && ticketUserId !== req.userId) {
      return res.status(403).json({ success: false, error: 'Not allowed to post on this ticket.' });
    }

    const messageText = (req.body && req.body.message) ? String(req.body.message).trim() : '';
    let imageUrl = null;
    if (req.file && req.file.buffer) {
      imageUrl = await uploadToCloudinary(req.file.buffer, 'apartment_management/support');
    }

    if (!messageText && !imageUrl) {
      return res.status(400).json({
        success: false,
        error: 'Message text or image is required.',
      });
    }

    const msg = await SupportMessage.create({
      ticketId,
      senderType: callerType,
      senderId: req.userId,
      message: messageText || '',
      imageUrl: imageUrl || undefined,
    });

    res.status(201).json({
      success: true,
      message: {
        id: msg._id.toString(),
        senderType: msg.senderType,
        message: msg.message || null,
        imageUrl: msg.imageUrl || null,
        createdAt: msg.createdAt,
      },
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update ticket status (admin only)
// @route   PATCH /api/support/tickets/:id/status
// @access  Private (Admin only)
const updateTicketStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, error: 'Invalid ticket id.' });
    }
    if (!['open', 'in_progress', 'closed'].includes(status)) {
      return res.status(400).json({ success: false, error: 'Invalid status. Use open, in_progress, or closed.' });
    }

    const callerType = await getCallerType(req);
    if (callerType !== 'admin') {
      return res.status(403).json({ success: false, error: 'Only admins can update ticket status.' });
    }

    const ticket = await Ticket.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    ).populate('userId', 'name block floor roomNumber');

    if (!ticket) {
      return res.status(404).json({ success: false, error: 'Ticket not found.' });
    }

    res.json({
      success: true,
      ticket: {
        id: ticket._id.toString(),
        userId: ticket.userId?._id?.toString(),
        issueType: ticket.issueType,
        description: ticket.description,
        status: ticket.status,
        createdAt: ticket.createdAt,
      },
    });
  } catch (error) {
    console.error('Update ticket status error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  createTicket,
  getTickets,
  getTicketById,
  getMessages,
  sendMessage,
  updateTicketStatus,
};
