const multer = require('multer');
const cloudinary = require('../config/cloudinary');

// Configure multer for memory storage (to upload to Cloudinary)
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  },
});

// Helper function to upload single image
const uploadSingleImage = (fieldName) => {
  return upload.single(fieldName);
};

// Helper function to upload multiple images
const uploadMultipleImages = (fieldName, maxCount = 5) => {
  return upload.array(fieldName, maxCount);
};

// Helper function to upload to Cloudinary from buffer
const uploadToCloudinary = async (fileBuffer, folder = 'apartment_management') => {
  return new Promise((resolve, reject) => {
    if (!fileBuffer) {
      reject(new Error('No file buffer provided'));
      return;
    }
    
    cloudinary.uploader.upload_stream(
      {
        folder: folder,
        resource_type: 'image',
        transformation: [{ width: 1000, height: 1000, crop: 'limit' }],
      },
      (error, result) => {
        if (error) {
          reject(error);
        } else {
          resolve(result.secure_url);
        }
      }
    ).end(fileBuffer);
  });
};

module.exports = {
  upload,
  uploadSingleImage,
  uploadMultipleImages,
  uploadToCloudinary,
};

