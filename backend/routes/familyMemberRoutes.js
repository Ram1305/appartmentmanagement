const express = require('express');
const router = express.Router();
const {
  createFamilyMember,
  getFamilyMembersByUser,
  deleteFamilyMember,
} = require('../controllers/familyMemberController');
const { protect } = require('../middleware/auth');
const { uploadSingleImage } = require('../middleware/upload');

router.get('/', protect, getFamilyMembersByUser);
router.post(
  '/',
  protect,
  uploadSingleImage('profileImage'),
  createFamilyMember
);
router.delete('/:id', protect, deleteFamilyMember);

module.exports = router;
