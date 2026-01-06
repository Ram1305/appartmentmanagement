# Frontend-Backend Integration Guide

## Overview
The Flutter frontend has been updated to connect with the Express.js + MongoDB backend API. All data is now fetched from the backend instead of local storage.

## Changes Made

### Frontend Updates

1. **Added Dependencies** (`pubspec.yaml`):
   - `http: ^1.1.0` - HTTP client
   - `dio: ^5.4.0` - Advanced HTTP client for file uploads

2. **Created API Service** (`lib/core/services/api_service.dart`):
   - Handles all API calls to backend
   - Manages JWT token storage
   - Handles image uploads using multipart form data
   - Error handling and response parsing

3. **Created API Config** (`lib/core/config/api_config.dart`):
   - Centralized API endpoint configuration
   - Base URL configuration for different environments

4. **Updated AuthRepository** (`lib/features/auth/data/repositories/auth_repository.dart`):
   - Now uses API service instead of local storage
   - Handles file uploads for registration
   - All methods now call backend API

5. **Updated AuthBloc** (`lib/features/auth/presentation/bloc/auth_bloc.dart`):
   - Updated RegisterUserEvent to accept file paths
   - All OTP and password reset methods now use API
   - Proper error handling from API responses

6. **Updated Registration Page** (`lib/features/auth/presentation/pages/user_registration_page.dart`):
   - Added password field
   - Updated to use new RegisterUserEvent structure
   - Images are now uploaded to backend (Cloudinary)

7. **Updated Forgot Password Page** (`lib/features/auth/presentation/pages/forgot_password_page.dart`):
   - Now uses backend API for OTP and password reset

### Backend Updates

1. **Updated Controllers** (`backend/controllers/authController.js`):
   - All user responses now return `id` as string (converted from MongoDB `_id`)
   - Proper error handling

## API Configuration

### Update API Base URL

Edit `lib/core/config/api_config.dart` and update the `baseUrl`:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000/api';

// For iOS Simulator
static const String baseUrl = 'http://localhost:5000/api';

// For Physical Device (use your computer's IP address)
static const String baseUrl = 'http://192.168.1.100:5000/api';
```

## Backend Setup

1. **Install Dependencies**:
```bash
cd backend
npm install
```

2. **Configure Environment Variables** (`.env`):
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/apartment_management
JWT_SECRET=your_secret_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
FRONTEND_URL=http://localhost:3000
```

3. **Start Backend Server**:
```bash
npm run dev
```

## Features Integrated

✅ User Registration with image uploads (Profile, Aadhaar, PAN)
✅ User Login with JWT authentication
✅ Email OTP Verification
✅ Password Reset with OTP
✅ All images stored in Cloudinary
✅ MongoDB database integration
✅ Token-based authentication
✅ Error handling and validation

## API Endpoints Used

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/send-otp` - Send OTP for email verification
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/forgot-password` - Request password reset OTP
- `POST /api/auth/reset-password` - Reset password
- `GET /api/auth/me` - Get current user (Protected)

## Testing

1. Start the backend server
2. Update API base URL in `api_config.dart` for your environment
3. Run the Flutter app
4. Test registration, login, and password reset flows

## Notes

- All images are uploaded to Cloudinary and only URLs are stored in MongoDB
- JWT tokens are stored in SharedPreferences
- The app falls back to local storage if API calls fail (for offline support)
- Make sure MongoDB and backend server are running before testing

