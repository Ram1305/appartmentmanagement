# Admin Registration API Documentation

## Overview
This API allows you to register admin users in the apartment management system.

## Default Admin User
A default admin user has been created with the following credentials:
- **Email**: admin@gmail.com
- **Username**: admin
- **Password**: 123456 (Note: Minimum 6 characters required by system)
- **Status**: Approved (automatically)

## API Endpoints

### 1. Register Admin
**POST** `/api/auth/register-admin`

Register a new admin user.

**Request Body:**
```json
{
  "name": "Admin Name",
  "username": "admin_username",
  "email": "admin@example.com",
  "password": "password123",
  "mobileNumber": "1234567890"
}
```

**Required Fields:**
- `name` (string): Full name of the admin
- `username` (string): Unique username
- `email` (string): Valid email address (must be unique)
- `password` (string): Password (minimum 6 characters)
- `mobileNumber` (string): 10-digit mobile number

**Success Response (201):**
```json
{
  "message": "Admin registered successfully",
  "user": {
    "id": "user_id",
    "name": "Admin Name",
    "username": "admin_username",
    "email": "admin@example.com",
    "mobileNumber": "1234567890",
    "userType": "admin",
    "status": "approved"
  },
  "token": "jwt_token_here"
}
```

**Error Response (400):**
```json
{
  "error": "Admin already exists with this email or username"
}
```

**Error Response (400):**
```json
{
  "error": "Please provide all required fields: name, username, email, password, mobileNumber"
}
```

## Initialize Default Admin

To create the default admin user, run:

```bash
npm run init-admin
```

This will create an admin with:
- Email: admin@gmail.com
- Username: admin
- Password: 123456

**Note:** If the admin already exists, the script will display the existing admin information and exit.

## Example Usage

### Using cURL:
```bash
curl -X POST http://localhost:5000/api/auth/register-admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Super Admin",
    "username": "superadmin",
    "email": "superadmin@example.com",
    "password": "securepassword123",
    "mobileNumber": "9876543210"
  }'
```

### Using JavaScript (fetch):
```javascript
const response = await fetch('http://localhost:5000/api/auth/register-admin', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'Super Admin',
    username: 'superadmin',
    email: 'superadmin@example.com',
    password: 'securepassword123',
    mobileNumber: '9876543210',
  }),
});

const data = await response.json();
console.log(data);
```

## Notes
- All admins are automatically approved (status: 'approved')
- Admin registration is currently public (no authentication required)
- You can register multiple admins using this endpoint
- Each admin must have a unique email and username

