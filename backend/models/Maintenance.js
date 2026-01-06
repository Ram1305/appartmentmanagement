const mongoose = require('mongoose');

const maintenanceSchema = new mongoose.Schema(
  {
    amount: {
      type: Number,
      required: [true, 'Maintenance amount is required'],
      min: [0, 'Amount must be positive'],
    },
    month: {
      type: String,
      required: true,
    },
    year: {
      type: Number,
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Maintenance', maintenanceSchema);

