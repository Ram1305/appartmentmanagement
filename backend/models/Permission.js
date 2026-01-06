const mongoose = require('mongoose');

const permissionSchema = new mongoose.Schema(
  {
    userType: {
      type: String,
      enum: ['admin', 'manager', 'security', 'user'],
      required: true,
      unique: true,
    },
    permissions: {
      viewUsers: { type: Boolean, default: false },
      editUsers: { type: Boolean, default: false },
      deleteUsers: { type: Boolean, default: false },
      viewBlocks: { type: Boolean, default: false },
      editBlocks: { type: Boolean, default: false },
      deleteBlocks: { type: Boolean, default: false },
      viewPayments: { type: Boolean, default: false },
      managePayments: { type: Boolean, default: false },
      viewReports: { type: Boolean, default: false },
      manageNotices: { type: Boolean, default: false },
      approveTenants: { type: Boolean, default: false },
      setMaintenance: { type: Boolean, default: false },
    },
  },
  {
    timestamps: true,
  }
);

permissionSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

permissionSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Permission', permissionSchema);

