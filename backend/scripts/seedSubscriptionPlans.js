const mongoose = require('mongoose');
const dotenv = require('dotenv');
const SubscriptionPlan = require('../models/SubscriptionPlan');

dotenv.config();

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Connected');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
};

const defaultPlans = [
  { name: 'Basic', daysValidity: 30, amount: 999, description: '1 month validity', displayOrder: 1, color: '#E3F2FD' },
  { name: 'Standard', daysValidity: 90, amount: 2499, description: '3 months validity', displayOrder: 2, color: '#E8F5E9' },
  { name: 'Premium', daysValidity: 365, amount: 8999, description: '1 year validity', displayOrder: 3, color: '#FFF8E1' },
];

const seed = async () => {
  await connectDB();
  const count = await SubscriptionPlan.countDocuments();
  if (count > 0) {
    console.log('Subscription plans already exist. Skipping seed.');
    process.exit(0);
  }
  await SubscriptionPlan.insertMany(defaultPlans);
  console.log('Created', defaultPlans.length, 'subscription plans.');
  process.exit(0);
};

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
