const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Admin = require('../models/Admin');

// Load env vars
dotenv.config();

// Connect to database
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

// Initialize default admin
const initAdmin = async () => {
  try {
    await connectDB();

    // Check if admin already exists in Admin collection
    const existingAdmin = await Admin.findOne({
      $or: [
        { email: 'admin@gmail.com' },
        { username: 'admin' },
      ],
    });

    if (existingAdmin) {
      console.log('Default admin already exists!');
      console.log('Email:', existingAdmin.email);
      console.log('Username:', existingAdmin.username);
      process.exit(0);
    }

    // Create default admin in Admin collection
    const admin = await Admin.create({
      name: 'Admin',
      username: 'admin',
      email: 'admin@gmail.com',
      password: '123456', // Minimum 6 characters required
      mobileNumber: '1234567890',
    });

    console.log('✅ Default admin created successfully!');
    console.log('Email: admin@gmail.com');
    console.log('Username: admin');
    console.log('Password: 123456');
    console.log('Admin ID:', admin._id.toString());

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating admin:', error.message);
    process.exit(1);
  }
};

// Run the script
initAdmin();
