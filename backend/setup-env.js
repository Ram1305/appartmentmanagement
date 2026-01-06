const fs = require('fs');
const path = require('path');

const envContent = `# Server Configuration
PORT=5000
NODE_ENV=development

# MongoDB Configuration
MONGODB_URI=mongodb+srv://appartmentmanagement:appartmentmanagement@cluster0.7wxxw0h.mongodb.net/apartment_management?retryWrites=true&w=majority&appName=Cluster0

# JWT Secret
JWT_SECRET=apartment_management_jwt_secret_key_2024

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Email Configuration (for OTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=ramram709428@gmail.com
EMAIL_PASS=mdofrbejmdfmbeqw

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:3000
`;

const envPath = path.join(__dirname, '.env');

const mongodbUri = 'mongodb+srv://appartmentmanagement:appartmentmanagement@cluster0.7wxxw0h.mongodb.net/apartment_management?retryWrites=true&w=majority&appName=Cluster0';

if (!fs.existsSync(envPath)) {
  fs.writeFileSync(envPath, envContent);
  console.log('✓ .env file created successfully!');
  console.log('✓ MongoDB URI configured');
  console.log('⚠ Please update Cloudinary and Email credentials in .env file');
} else {
  console.log('.env file already exists');
  // Update MONGODB_URI
  let existingContent = fs.readFileSync(envPath, 'utf8');
  
  // Check if MONGODB_URI exists and update it
  if (existingContent.includes('MONGODB_URI=')) {
    existingContent = existingContent.replace(
      /MONGODB_URI=.*/,
      `MONGODB_URI=${mongodbUri}`
    );
    fs.writeFileSync(envPath, existingContent);
    console.log('✓ MONGODB_URI updated in .env file');
  } else {
    // Add MONGODB_URI if it doesn't exist
    existingContent += `\nMONGODB_URI=${mongodbUri}\n`;
    fs.writeFileSync(envPath, existingContent);
    console.log('✓ MONGODB_URI added to .env file');
  }
  
  // Update EMAIL_USER if it exists
  if (existingContent.includes('EMAIL_USER=')) {
    existingContent = existingContent.replace(
      /EMAIL_USER=.*/,
      'EMAIL_USER=ramram709428@gmail.com'
    );
  } else {
    existingContent += '\nEMAIL_USER=ramram709428@gmail.com\n';
  }
  
  // Update EMAIL_PASS if it exists (remove spaces from app password)
  const emailPass = 'mdofrbejmdfmbeqw'; // Gmail app password without spaces
  if (existingContent.includes('EMAIL_PASS=')) {
    existingContent = existingContent.replace(
      /EMAIL_PASS=.*/,
      `EMAIL_PASS=${emailPass}`
    );
  } else {
    existingContent += `\nEMAIL_PASS=${emailPass}\n`;
  }
  
  // Update EMAIL_HOST and EMAIL_PORT
  if (existingContent.includes('EMAIL_HOST=')) {
    existingContent = existingContent.replace(
      /EMAIL_HOST=.*/,
      'EMAIL_HOST=smtp.gmail.com'
    );
  } else {
    existingContent += '\nEMAIL_HOST=smtp.gmail.com\n';
  }
  
  if (existingContent.includes('EMAIL_PORT=')) {
    existingContent = existingContent.replace(
      /EMAIL_PORT=.*/,
      'EMAIL_PORT=587'
    );
  } else {
    existingContent += '\nEMAIL_PORT=587\n';
  }
  
  fs.writeFileSync(envPath, existingContent);
  console.log('✓ Email credentials updated in .env file');
}

