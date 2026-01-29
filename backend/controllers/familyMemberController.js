const FamilyMember = require('../models/FamilyMember');
const { uploadToCloudinary } = require('../middleware/upload');

// @desc    Create family member
// @route   POST /api/family-members
// @access  Private (User)
const createFamilyMember = async (req, res) => {
  try {
    const { name, relationType, dateOfBirth } = req.body;

    if (!name || !relationType) {
      return res.status(400).json({
        success: false,
        error: 'Name and relation type are required',
      });
    }

    const validRelations = ['spouse', 'child', 'parent', 'sibling', 'grandparent', 'other'];
    if (!validRelations.includes(relationType)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid relation type',
      });
    }

    let profileImageUrl;
    if (req.file && req.file.buffer) {
      profileImageUrl = await uploadToCloudinary(
        req.file.buffer,
        'apartment_management/family_members'
      );
    }

    const familyMember = await FamilyMember.create({
      user: req.userId,
      name: name.trim(),
      relationType,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
      profileImage: profileImageUrl || undefined,
    });

    res.status(201).json({
      success: true,
      message: 'Family member added successfully',
      familyMember,
    });
  } catch (error) {
    console.error('Create family member error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get family members by current user
// @route   GET /api/family-members
// @access  Private (User)
const getFamilyMembersByUser = async (req, res) => {
  try {
    const familyMembers = await FamilyMember.find({ user: req.userId }).sort({
      createdAt: -1,
    });

    res.json({
      success: true,
      count: familyMembers.length,
      familyMembers,
    });
  } catch (error) {
    console.error('Get family members error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete family member
// @route   DELETE /api/family-members/:id
// @access  Private (User - own family member only)
const deleteFamilyMember = async (req, res) => {
  try {
    const familyMember = await FamilyMember.findById(req.params.id);
    if (!familyMember) {
      return res.status(404).json({
        success: false,
        error: 'Family member not found',
      });
    }
    if (familyMember.user.toString() !== req.userId) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to delete this family member',
      });
    }
    await FamilyMember.findByIdAndDelete(req.params.id);
    res.json({
      success: true,
      message: 'Family member deleted successfully',
    });
  } catch (error) {
    console.error('Delete family member error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  createFamilyMember,
  getFamilyMembersByUser,
  deleteFamilyMember,
};
