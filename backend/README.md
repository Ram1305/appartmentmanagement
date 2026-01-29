# Apartment Management Backend API

Express.js + MongoDB backend for Apartment Management System.

## Features

- User Registration with image uploads (Cloudinary)
- User Login
- Email OTP Verification
- Password Reset with OTP
- JWT Authentication
- MongoDB Database
- Cloudinary Image Storage

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Update the following in `.env`:
- `MONGODB_URI`: `mongodb+srv://appartmentmanagement:appartmentmanagement@cluster0.7wxxw0h.mongodb.net/?appName=Cluster0` (already configured)
- `JWT_SECRET`: A random secret key for JWT tokens (default provided)
- `CLOUDINARY_CLOUD_NAME`: Your Cloudinary cloud name
- `CLOUDINARY_API_KEY`: Your Cloudinary API key
- `CLOUDINARY_API_SECRET`: Your Cloudinary API secret
- `EMAIL_USER`: Your email for sending OTPs
- `EMAIL_PASS`: Your email app password
- `FRONTEND_URL`: Your frontend URL (for CORS)
- `RAZORPAY_KEY_ID`: Your Razorpay API key (from Razorpay Dashboard)
- `RAZORPAY_KEY_SECRET`: Your Razorpay API secret (from Razorpay Dashboard) — used for payments and admin subscription

### 3. Start MongoDB

Make sure MongoDB is running on your system or use MongoDB Atlas.

### 4. Run the Server

Development mode (with nodemon):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

Server will run on `http://localhost:5000`

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/send-otp` - Send OTP for email verification
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/forgot-password` - Send password reset OTP
- `POST /api/auth/reset-password` - Reset password
- `GET /api/auth/me` - Get current user (Protected)

### Health Check

- `GET /api/health` - Check API status

## Request/Response Examples

### Register User

**Request:**
```
POST /api/auth/register
Content-Type: multipart/form-data

Fields:
- name: "John Doe"
- username: "johndoe"
- email: "john@example.com"
- password: "password123"
- mobileNumber: "1234567890"
- secondaryMobileNumber: "0987654321" (optional)
- gender: "male" (optional)
- userType: "user"
- familyType: "family" (optional)
- aadhaarCard: "123456789012" (optional)
- panCard: "ABCDE1234F" (optional)
- totalOccupants: 4 (optional)
- block: "A" (optional)
- floor: "2" (optional)
- roomNumber: "201" (optional)
- profilePic: (file)
- aadhaarFront: (file)
- aadhaarBack: (file)
- panCard: (file)
```

**Response:**
```json
{
  "message": "User registered successfully",
  "user": { ... },
  "token": "jwt_token_here"
}
```

### Login

**Request:**
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123",
  "userType": "user" (optional)
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user": { ... },
  "token": "jwt_token_here"
}
```

## Project Structure

```
backend/
├── config/
│   ├── database.js          # MongoDB connection
│   └── cloudinary.js        # Cloudinary configuration
├── controllers/
│   └── authController.js    # Authentication logic
├── middleware/
│   ├── auth.js              # JWT authentication middleware
│   └── upload.js            # File upload middleware
├── models/
│   └── User.js              # User model
├── routes/
│   └── authRoutes.js        # Authentication routes
├── utils/
│   ├── emailService.js      # Email service for OTP
│   └── generateToken.js     # JWT token generation
├── .env                     # Environment variables
├── .env.example            # Environment variables template
├── .gitignore
├── index.js                # Main server file
├── package.json
└── README.md
```

## Technologies Used

- Express.js - Web framework
- MongoDB - Database
- Mongoose - MongoDB ODM
- JWT - Authentication
- Bcrypt - Password hashing
- Cloudinary - Image storage
- Nodemailer - Email service
- Multer - File upload handling

