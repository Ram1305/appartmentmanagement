const mongoose = require('mongoose');

const LINE_ITEM_TYPES = [
  'Maintenance',
  'Rent',
  'Parking',
  'Amenities usage',
  'Penalty',
  'Electricity',
  'Water',
];

const lineItemSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      required: true,
      enum: LINE_ITEM_TYPES,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
  },
  { _id: false }
);

const paymentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    amount: {
      type: Number,
      default: 0,
    },
    lineItems: {
      type: [lineItemSchema],
      default: [],
    },
    totalAmount: {
      type: Number,
      default: 0,
    },
    month: {
      type: String,
      required: true,
    },
    year: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'overdue'],
      default: 'pending',
    },
    paymentDate: {
      type: Date,
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'online', 'cheque', 'other'],
    },
    transactionId: {
      type: String,
    },
    razorpayOrderId: {
      type: String,
    },
    notes: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

paymentSchema.virtual('id').get(function () {
  return this._id.toHexString();
});

paymentSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Payment', paymentSchema);
module.exports.LINE_ITEM_TYPES = LINE_ITEM_TYPES;
