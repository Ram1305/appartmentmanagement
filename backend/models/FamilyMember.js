const mongoose = require('mongoose');

const familyMemberSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
    },
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    relationType: {
      type: String,
      enum: ['spouse', 'child', 'parent', 'sibling', 'grandparent', 'other'],
      required: [true, 'Relation type is required'],
    },
    dateOfBirth: {
      type: Date,
    },
    profileImage: {
      type: String, // Cloudinary URL
    },
  },
  {
    timestamps: true,
  }
);

familyMemberSchema.index({ user: 1 });

module.exports = mongoose.model('FamilyMember', familyMemberSchema);
