const KidExit = require('../models/KidExit');
const User = require('../models/User');
const Security = require('../models/Security');

// @desc    Report kid exit (resident notifies security that a child is leaving)
// @route   POST /api/kid-exits
// @access  Private (User/Resident only)
const createKidExit = async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      const security = await Security.findById(req.userId);
      if (security) {
        return res.status(403).json({
          success: false,
          error: 'Only residents can report kid exit. Use the app as a resident to report.',
        });
      }
      return res.status(401).json({
        success: false,
        error: 'User not found',
      });
    }

    if (!user.block || !user.roomNumber) {
      return res.status(400).json({
        success: false,
        error: 'Your account must have block and room assigned to report kid exit',
      });
    }

    const { kidName, familyMemberId, note } = req.body;
    if (!kidName || typeof kidName !== 'string' || !kidName.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Kid name is required',
      });
    }

    const exitTime = req.body.exitTime ? new Date(req.body.exitTime) : new Date();
    const kidExit = await KidExit.create({
      reportedBy: req.userId,
      kidName: kidName.trim(),
      familyMemberId: familyMemberId || null,
      block: user.block,
      homeNumber: user.roomNumber,
      exitTime,
      note: (note && typeof note === 'string' ? note.trim() : '') || '',
    });

    const populated = await KidExit.findById(kidExit._id)
      .populate('reportedBy', 'name email mobileNumber')
      .lean();

    res.status(201).json({
      success: true,
      message: 'Kid exit reported. Security has been notified.',
      kidExit: populated,
    });
  } catch (err) {
    console.error('createKidExit error:', err);
    res.status(500).json({
      success: false,
      error: err.message || 'Failed to report kid exit',
    });
  }
};

// @desc    Get kid exits - residents see their unit's exits; security sees all (optionally filtered by date)
// @route   GET /api/kid-exits
// @access  Private (User or Security)
const getKidExits = async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    const security = await Security.findById(req.userId);

    let query = {};
    if (user && !security) {
      if (!user.block || !user.roomNumber) {
        return res.json({ success: true, kidExits: [] });
      }
      query = { block: user.block, homeNumber: user.roomNumber };
    }
    // If security (or both), list all; optional date filter for security
    const { date, from, to } = req.query;
    if (date) {
      const start = new Date(date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(date);
      end.setHours(23, 59, 59, 999);
      query.exitTime = { $gte: start, $lte: end };
    } else if (from && to) {
      query.exitTime = {
        $gte: new Date(from),
        $lte: new Date(to),
      };
    }

    const kidExits = await KidExit.find(query)
      .populate('reportedBy', 'name email mobileNumber')
      .sort({ exitTime: -1 })
      .limit(200)
      .lean();

    res.json({
      success: true,
      kidExits,
    });
  } catch (err) {
    console.error('getKidExits error:', err);
    res.status(500).json({
      success: false,
      error: err.message || 'Failed to fetch kid exits',
    });
  }
};

// @desc    Acknowledge kid exit (security marks as seen)
// @route   PATCH /api/kid-exits/:id/acknowledge
// @access  Private (Security only)
const acknowledgeKidExit = async (req, res) => {
  try {
    const security = await Security.findById(req.userId);
    if (!security) {
      return res.status(403).json({
        success: false,
        error: 'Only security can acknowledge kid exit',
      });
    }

    const kidExit = await KidExit.findByIdAndUpdate(
      req.params.id,
      { acknowledgedAt: new Date(), acknowledgedBy: req.userId },
      { new: true }
    )
      .populate('reportedBy', 'name email mobileNumber')
      .lean();

    if (!kidExit) {
      return res.status(404).json({
        success: false,
        error: 'Kid exit record not found',
      });
    }

    res.json({
      success: true,
      message: 'Kid exit acknowledged',
      kidExit,
    });
  } catch (err) {
    console.error('acknowledgeKidExit error:', err);
    res.status(500).json({
      success: false,
      error: err.message || 'Failed to acknowledge',
    });
  }
};

module.exports = {
  createKidExit,
  getKidExits,
  acknowledgeKidExit,
};
