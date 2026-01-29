const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/database');
const securityHeaders = require('./middleware/securityHeaders');
const Admin = require('./models/Admin');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

// Run every hour: expire admin subscriptions whose subscriptionEndsAt has passed
const ONE_HOUR_MS = 60 * 60 * 1000;
setInterval(async () => {
  try {
    const result = await Admin.updateMany(
      { subscriptionEndsAt: { $lte: new Date() } },
      { $set: { subscriptionStatus: false } }
    );
    if (result.modifiedCount > 0) {
      console.log(`[Cron] Expired ${result.modifiedCount} admin subscription(s).`);
    }
  } catch (err) {
    console.error('[Cron] Subscription expiry error:', err);
  }
}, ONE_HOUR_MS);

const app = express();

// Security headers middleware (apply to all routes)
app.use(securityHeaders);

// Middleware - CORS configuration
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5000',
  'http://localhost:7000',
  'http://127.0.0.1:5000',
  'http://127.0.0.1:7000',
  'http://192.168.29.61:5000',
  'http://192.168.29.61',
  'http://10.21.175.15:5000', // Previous IP
  'http://10.36.111.15:5000', // Current IP
  'http://72.61.236.154:5000', // Production HTTPS server
  // Add Flutter app origins
  'http://10.0.2.2:5000', // Android emulator
  'http://localhost:5000', // iOS simulator
];

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Check if origin is in allowed list
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      // Allow any origin for development (you can restrict this in production)
      // This is useful for Flutter apps and mobile devices
      if (process.env.NODE_ENV === 'production') {
        callback(new Error('Not allowed by CORS'));
      } else {
        callback(null, true);
      }
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['Content-Range', 'X-Content-Range'],
  preflightContinue: false,
  optionsSuccessStatus: 204,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/blocks', require('./routes/blockRoutes'));
app.use('/api/maintenance', require('./routes/maintenanceRoutes'));
app.use('/api/payments', require('./routes/paymentRoutes'));
app.use('/api/notices', require('./routes/noticeRoutes'));
app.use('/api/permissions', require('./routes/permissionRoutes'));
app.use('/api/visitors', require('./routes/visitorRoutes'));
app.use('/api/vehicles', require('./routes/vehicleRoutes'));
app.use('/api/family-members', require('./routes/familyMemberRoutes'));
app.use('/api/ads', require('./routes/adRoutes'));
app.use('/api/amenities', require('./routes/amenityRoutes'));
app.use('/api/support', require('./routes/supportRoutes'));
app.use('/api/subscription', require('./routes/subscriptionRoutes'));

// Health check route
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Apartment Management API is running',
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: err.message || 'Something went wrong!',
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
  });
});

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all interfaces

app.listen(PORT, HOST, () => {
  console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on ${HOST}:${PORT}`);
  console.log(`CORS enabled for all origins in development mode`);
});

