const express = require('express');
const router = express.Router();
const {
  createFamilyMember,
  getFamilyMembersByUser,
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

module.exports = router;
