const User = require('../models/User');
const Admin = require('../models/Admin');
const Manager = require('../models/Manager');
const Security = require('../models/Security');
const generateToken = require('../utils/generateToken');
const { sendOTPEmail, sendPasswordResetEmail } = require('../utils/emailService');
const { uploadToCloudinary } = require('../middleware/upload');

// Temporary OTP storage for registration (in-memory)
// Format: { email: { otp: string, expiry: number } }
const tempOtpStore = new Map();

// Cleanup expired OTPs every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [email, data] of tempOtpStore.entries()) {
    if (data.expiry <= now) {
      tempOtpStore.delete(email);
      console.log(`Cleaned up expired OTP for ${email}`);
    }
  }
}, 5 * 60 * 1000); // Run every 5 minutes

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = async (req, res) => {
  try {
    const {
      name,
      username,
      email,
      password,
      mobileNumber,
      secondaryMobileNumber,
      gender,
      userType,
      familyType,
      aadhaarCard,
      panCard,
      totalOccupants,
      block,
      floor,
      roomNumber,
    } = req.body;

    // Check if user already exists across all collections
    const UserModel = userType === 'admin' ? Admin : 
                     userType === 'manager' ? Manager : 
                     userType === 'security' ? Security : User;
    
    // Check in the specific collection
    const userExists = await UserModel.findOne({
      $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }],
    });

    if (userExists) {
      return res.status(400).json({
        error: 'User already exists with this email or username',
      });
    }

    // Also check in other collections to ensure uniqueness across all
    const allModels = [User, Admin, Manager, Security];
    for (const Model of allModels) {
      if (Model !== UserModel) {
        const exists = await Model.findOne({
          $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }],
        });
        if (exists) {
          return res.status(400).json({
            error: 'User already exists with this email or username',
          });
        }
      }
    }

    // Upload images to Cloudinary if provided
    let profilePicUrl = null;
    let aadhaarFrontUrl = null;
    let aadhaarBackUrl = null;
    let panCardUrl = null;

    if (req.files) {
      if (req.files.profilePic && req.files.profilePic[0]) {
        profilePicUrl = await uploadToCloudinary(
          req.files.profilePic[0].buffer,
          'apartment_management/profile_pics'
        );
      }
      if (req.files.aadhaarFront && req.files.aadhaarFront[0]) {
        aadhaarFrontUrl = await uploadToCloudinary(
          req.files.aadhaarFront[0].buffer,
          'apartment_management/id_cards'
        );
      }
      if (req.files.aadhaarBack && req.files.aadhaarBack[0]) {
        aadhaarBackUrl = await uploadToCloudinary(
          req.files.aadhaarBack[0].buffer,
          'apartment_management/id_cards'
        );
      }
      if (req.files.panCard && req.files.panCard[0]) {
        panCardUrl = await uploadToCloudinary(
          req.files.panCard[0].buffer,
          'apartment_management/pan_cards'
        );
      }
    }

    // Create user in the appropriate collection
    const userData = {
      name,
      username: username.toLowerCase(),
      email: email.toLowerCase(),
      password,
      mobileNumber,
      secondaryMobileNumber: secondaryMobileNumber || undefined,
      gender: gender || undefined,
      status: userType === 'admin' || userType === 'manager' || userType === 'security' ? 'approved' : 'pending',
      profilePic: profilePicUrl,
      aadhaarCard: aadhaarCard || undefined,
      aadhaarCardFrontImage: aadhaarFrontUrl,
      aadhaarCardBackImage: aadhaarBackUrl,
      panCard: panCard || undefined,
      panCardImage: panCardUrl,
    };

    // Add user-specific fields only for regular users
    if (userType === 'user' || !userType) {
      userData.familyType = familyType || undefined;
      userData.totalOccupants = totalOccupants ? parseInt(totalOccupants) : undefined;
      userData.block = block || undefined;
      userData.floor = floor || undefined;
      userData.roomNumber = roomNumber || undefined;
    }

    const user = await UserModel.create(userData);

    if (user) {
      const token = generateToken(user._id);
      res.status(201).json({
        message: 'User registered successfully',
        user: {
          id: user._id.toString(),
          name: user.name,
          username: user.username,
          email: user.email,
          mobileNumber: user.mobileNumber,
          secondaryMobileNumber: user.secondaryMobileNumber,
          gender: user.gender,
          userType: user.userType,
          status: user.status,
          profilePic: user.profilePic,
          aadhaarCard: user.aadhaarCard,
          aadhaarCardFrontImage: user.aadhaarCardFrontImage,
          aadhaarCardBackImage: user.aadhaarCardBackImage,
          panCard: user.panCard,
          panCardImage: user.panCardImage,
          familyType: user.familyType,
          totalOccupants: user.totalOccupants,
        block: user.block,
        floor: user.floor,
        roomNumber: user.roomNumber,
        isActive: user.isActive,
      },
      token,
    });
    } else {
      res.status(400).json({
        error: 'Invalid user data',
      });
    }
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
  try {
    const { email, password, userType } = req.body;
    
    console.log('=== LOGIN ATTEMPT ===');
    console.log('Email:', email);
    console.log('Requested userType:', userType);
    console.log('Password provided:', password ? 'Yes (hidden)' : 'No');

    // Check all collections for the user and determine which model they belong to
    // Check Admin, Manager, Security first, then User (to prioritize admin/manager/security over regular users)
    let user = null;
    let foundModelType = null;
    const modelMap = [
      { Model: Admin, type: 'admin' },
      { Model: Manager, type: 'manager' },
      { Model: Security, type: 'security' },
      { Model: User, type: 'user' }
    ];
    
    console.log('Searching for user in collections...');
    for (const { Model, type } of modelMap) {
      console.log(`Checking ${type} collection...`);
      user = await Model.findOne({ email: email.toLowerCase() }).select('+password');
      if (user) {
        foundModelType = type;
        console.log(`✓ User found in ${type} collection`);
        console.log(`User ID: ${user._id}`);
        console.log(`User name: ${user.name}`);
        console.log(`User email: ${user.email}`);
        console.log(`User userType in DB: ${user.userType}`);
        console.log(`User isActive: ${user.isActive}`);
        console.log(`User status: ${user.status}`);
        break;
      } else {
        console.log(`✗ Not found in ${type} collection`);
      }
    }

    if (!user) {
      console.log('ERROR: User not found in any collection');
      return res.status(401).json({
        error: 'Invalid email or password',
      });
    }

    console.log('Verifying password...');
    const isPasswordMatch = await user.comparePassword(password);
    console.log('Password match:', isPasswordMatch);

    if (!isPasswordMatch) {
      console.log('ERROR: Password does not match');
      return res.status(401).json({
        error: 'Invalid email or password',
      });
    }

    // Check if user is active
    console.log('Checking if user is active...');
    if (!user.isActive) {
      console.log('ERROR: User account is deactivated');
      return res.status(403).json({
        error: 'Your account has been deactivated. Please contact administrator.',
      });
    }

    // Use the user's actual userType field for validation, not just the collection
    // This handles cases where admin/manager might be in User collection but have correct userType
    const actualUserType = user.userType || foundModelType;
    console.log('Checking userType...');
    console.log(`Current user.userType: ${user.userType}`);
    console.log(`Found model type: ${foundModelType}`);
    console.log(`Actual userType to use: ${actualUserType}`);

    // Update userType if it doesn't match the collection (for data consistency)
    if (!user.userType || user.userType !== foundModelType) {
      console.log('Updating userType to match found model type...');
      user.userType = foundModelType;
      // Only update status if it's admin or manager
      if (foundModelType === 'admin' || foundModelType === 'manager') {
        user.status = 'approved';
        console.log('Setting status to approved for admin/manager');
      }
      try {
        await user.save();
        console.log('✓ UserType updated successfully in database');
      } catch (saveError) {
        // If save fails (e.g., immutable field), just continue with the actualUserType
        console.log('⚠ Note: Could not update userType in database, using actual userType:', actualUserType);
        console.log('Save error:', saveError.message);
      }
    } else {
      console.log('✓ UserType already matches found model type');
    }

    // Check user type if specified - use actualUserType for comparison (not just foundModelType)
    console.log('Validating requested userType...');
    console.log(`Requested userType: "${userType}" (type: ${typeof userType})`);
    console.log(`Actual userType: "${actualUserType}" (type: ${typeof actualUserType})`);
    
    // Normalize both values for comparison (trim and lowercase)
    const normalizedRequestedType = userType ? userType.toString().toLowerCase().trim() : null;
    const normalizedActualType = actualUserType ? actualUserType.toString().toLowerCase().trim() : null;
    
    console.log(`Normalized requested: "${normalizedRequestedType}"`);
    console.log(`Normalized actual: "${normalizedActualType}"`);
    
    if (normalizedRequestedType && normalizedActualType !== normalizedRequestedType) {
      console.log(`ERROR: UserType mismatch! Requested: "${normalizedRequestedType}", Actual: "${normalizedActualType}"`);
      return res.status(403).json({
        error: `Access denied. This account is not a ${userType}`,
      });
    }
    console.log('✓ UserType validation passed');

    const token = generateToken(user._id);
    console.log('Token generated successfully');

    // Use actualUserType to ensure correct userType is returned
    const finalUserType = actualUserType || foundModelType || 'user';
    console.log(`Final userType to return: ${finalUserType}`);

    console.log('=== LOGIN SUCCESS ===');
    console.log('Returning user data...');
    
    res.json({
      message: 'Login successful',
      user: {
        id: user._id.toString(),
        name: user.name,
        username: user.username,
        email: user.email,
        mobileNumber: user.mobileNumber,
        secondaryMobileNumber: user.secondaryMobileNumber,
        gender: user.gender,
        userType: finalUserType,
        status: user.status,
        profilePic: user.profilePic,
        aadhaarCard: user.aadhaarCard,
        aadhaarCardFrontImage: user.aadhaarCardFrontImage,
        aadhaarCardBackImage: user.aadhaarCardBackImage,
        panCard: user.panCard,
        panCardImage: user.panCardImage,
        familyType: user.familyType,
        totalOccupants: user.totalOccupants,
        block: user.block,
        floor: user.floor,
        roomNumber: user.roomNumber,
        isActive: user.isActive,
      },
      token,
    });
  } catch (error) {
    console.error('=== LOGIN ERROR ===');
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Send OTP for email verification
// @route   POST /api/auth/send-otp
// @access  Public
const sendOTP = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Email is required',
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    console.log('=== SEND OTP ===');
    console.log('Email:', normalizedEmail);

    // Check all collections for existing user (like login does)
    let user = null;
    const modelMap = [
      { Model: Admin, type: 'admin' },
      { Model: Manager, type: 'manager' },
      { Model: Security, type: 'security' },
      { Model: User, type: 'user' }
    ];
    
    console.log('Checking if user exists in collections...');
    for (const { Model, type } of modelMap) {
      user = await Model.findOne({ email: normalizedEmail });
      if (user) {
        console.log(`✓ User found in ${type} collection`);
        break;
      }
    }

    let otp;
    if (user) {
      // User exists - generate OTP and save to user document
      console.log('User exists, generating OTP and saving to user document');
      otp = user.generateOTP();
      await user.save();
    } else {
      // User doesn't exist (registration flow) - store OTP temporarily
      console.log('User does not exist, storing OTP temporarily for registration');
      otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiry = Date.now() + 10 * 60 * 1000; // 10 minutes
      tempOtpStore.set(normalizedEmail, { otp, expiry });
      console.log(`OTP stored temporarily for ${normalizedEmail}, expires in 10 minutes`);
    }

    // Send OTP via email
    console.log('Sending OTP email...');
    const emailSent = await sendOTPEmail(normalizedEmail, otp);

    if (emailSent) {
      console.log('✓ OTP email sent successfully');
      res.json({
        message: 'OTP sent to your email',
      });
    } else {
      console.log('✗ Failed to send OTP email');
      // Clean up temporary OTP if stored
      if (!user) {
        tempOtpStore.delete(normalizedEmail);
      }
      res.status(500).json({
        error: 'Failed to send OTP email',
      });
    }
  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Verify OTP
// @route   POST /api/auth/verify-otp
// @access  Public
const verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        error: 'Email and OTP are required',
      });
    }

    const normalizedEmail = email.toLowerCase().trim();
    console.log('=== VERIFY OTP ===');
    console.log('Email:', normalizedEmail);
    console.log('OTP:', otp);

    // Check all collections for existing user
    let user = null;
    const modelMap = [
      { Model: Admin, type: 'admin' },
      { Model: Manager, type: 'manager' },
      { Model: Security, type: 'security' },
      { Model: User, type: 'user' }
    ];
    
    console.log('Checking if user exists in collections...');
    for (const { Model, type } of modelMap) {
      user = await Model.findOne({ email: normalizedEmail }).select('+otp +otpExpiry');
      if (user) {
        console.log(`✓ User found in ${type} collection`);
        break;
      }
    }

    let isValid = false;
    if (user) {
      // User exists - verify OTP from user document
      console.log('User exists, verifying OTP from user document');
      isValid = user.verifyOTP(otp);
      if (isValid) {
        // Clear OTP after verification
        user.otp = undefined;
        user.otpExpiry = undefined;
        await user.save();
        console.log('✓ OTP verified and cleared from user document');
      }
    } else {
      // User doesn't exist - check temporary OTP store (registration flow)
      console.log('User does not exist, checking temporary OTP store');
      const tempOtpData = tempOtpStore.get(normalizedEmail);
      if (tempOtpData) {
        if (tempOtpData.otp === otp) {
          if (tempOtpData.expiry > Date.now()) {
            isValid = true;
            // Remove temporary OTP after verification
            tempOtpStore.delete(normalizedEmail);
            console.log('✓ OTP verified from temporary store and removed');
          } else {
            console.log('✗ Temporary OTP expired');
            tempOtpStore.delete(normalizedEmail);
          }
        } else {
          console.log('✗ Temporary OTP does not match');
        }
      } else {
        console.log('✗ No temporary OTP found for this email');
      }
    }

    if (!isValid) {
      return res.status(400).json({
        error: 'Invalid or expired OTP',
      });
    }

    res.json({
      message: 'OTP verified successfully',
      verified: true,
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Send password reset OTP
// @route   POST /api/auth/forgot-password
// @access  Public
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Email is required',
      });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      return res.status(404).json({
        error: 'User not found with this email',
      });
    }

    const otp = user.generateOTP();
    await user.save();

    // Send password reset OTP via email
    const emailSent = await sendPasswordResetEmail(email, otp);

    if (emailSent) {
      res.json({
        message: 'Password reset OTP sent to your email',
      });
    } else {
      res.status(500).json({
        error: 'Failed to send OTP email',
      });
    }
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Reset password
// @route   POST /api/auth/reset-password
// @access  Public
const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        error: 'Email, OTP, and new password are required',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        error: 'Password must be at least 6 characters',
      });
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select('+otp +otpExpiry +password');

    if (!user) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    const isValid = user.verifyOTP(otp);

    if (!isValid) {
      return res.status(400).json({
        error: 'Invalid or expired OTP',
      });
    }

    // Update password
    user.password = newPassword;
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();

    res.json({
      message: 'Password reset successfully',
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
const getCurrentUser = async (req, res) => {
  try {
    // Check all collections for the user
    let user = null;
    const allModels = [User, Admin, Manager, Security];
    
    for (const Model of allModels) {
      user = await Model.findById(req.userId);
      if (user) break;
    }

    if (!user) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    res.json({
      user: {
        id: user._id.toString(),
        name: user.name,
        username: user.username,
        email: user.email,
        mobileNumber: user.mobileNumber,
        secondaryMobileNumber: user.secondaryMobileNumber,
        gender: user.gender,
        userType: user.userType,
        status: user.status,
        profilePic: user.profilePic,
        aadhaarCard: user.aadhaarCard,
        aadhaarCardFrontImage: user.aadhaarCardFrontImage,
        aadhaarCardBackImage: user.aadhaarCardBackImage,
        panCard: user.panCard,
        panCardImage: user.panCardImage,
        familyType: user.familyType,
        totalOccupants: user.totalOccupants,
        block: user.block,
        floor: user.floor,
        roomNumber: user.roomNumber,
        isActive: user.isActive,
      },
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Register a new admin
// @route   POST /api/auth/register-admin
// @access  Public (can be protected later)
const registerAdmin = async (req, res) => {
  try {
    const {
      name,
      username,
      email,
      password,
      mobileNumber,
    } = req.body;

    // Validate required fields
    if (!name || !username || !email || !password || !mobileNumber) {
      return res.status(400).json({
        error: 'Please provide all required fields: name, username, email, password, mobileNumber',
      });
    }

    // Check if admin already exists in Admin collection
    const adminExists = await Admin.findOne({
      $or: [
        { email: email.toLowerCase() },
        { username: username.toLowerCase() },
      ],
    });

    if (adminExists) {
      return res.status(400).json({
        error: 'Admin already exists with this email or username',
      });
    }

    // Also check in other collections to ensure uniqueness
    const allModels = [User, Manager, Security];
    for (const Model of allModels) {
      const exists = await Model.findOne({
        $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }],
      });
      if (exists) {
        return res.status(400).json({
          error: 'User already exists with this email or username',
        });
      }
    }

    // Create admin user in Admin collection
    const admin = await Admin.create({
      name,
      username: username.toLowerCase(),
      email: email.toLowerCase(),
      password,
      mobileNumber,
      status: 'approved', // Admins are auto-approved
    });

    // Generate token
    const token = generateToken(admin._id);

    res.status(201).json({
      message: 'Admin registered successfully',
      user: {
        id: admin._id.toString(),
        name: admin.name,
        username: admin.username,
        email: admin.email,
        mobileNumber: admin.mobileNumber,
        userType: admin.userType,
        status: admin.status,
        isActive: admin.isActive,
      },
      token,
    });
  } catch (error) {
    console.error('Admin registration error:', error);
    res.status(500).json({
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get all users
// @route   GET /api/auth/users
// @access  Public (should be protected in production)
const getAllUsers = async (req, res) => {
  try {
    // Get users from all collections
    const [regularUsers, admins, managers, securityStaff] = await Promise.all([
      User.find().select('-password -otp -otpExpiry -resetPasswordToken -resetPasswordExpiry').sort({ createdAt: -1 }),
      Admin.find().select('-password -otp -otpExpiry -resetPasswordToken -resetPasswordExpiry').sort({ createdAt: -1 }),
      Manager.find().select('-password -otp -otpExpiry -resetPasswordToken -resetPasswordExpiry').sort({ createdAt: -1 }),
      Security.find().select('-password -otp -otpExpiry -resetPasswordToken -resetPasswordExpiry').sort({ createdAt: -1 }),
    ]);

    // Combine all users
    const users = [...regularUsers, ...admins, ...managers, ...securityStaff].sort((a, b) => 
      new Date(b.createdAt) - new Date(a.createdAt)
    );

    res.json({
      success: true,
      count: users.length,
      users: users.map(user => ({
        id: user._id.toString(),
        name: user.name,
        username: user.username,
        email: user.email,
        mobileNumber: user.mobileNumber,
        secondaryMobileNumber: user.secondaryMobileNumber,
        gender: user.gender,
        userType: user.userType,
        status: user.status,
        profilePic: user.profilePic,
        address: user.address,
        aadhaarCard: user.aadhaarCard,
        aadhaarCardFrontImage: user.aadhaarCardFrontImage,
        aadhaarCardBackImage: user.aadhaarCardBackImage,
        panCard: user.panCard,
        panCardImage: user.panCardImage,
        familyType: user.familyType,
        totalOccupants: user.totalOccupants,
        block: user.block,
        floor: user.floor,
        roomNumber: user.roomNumber,
        isActive: user.isActive,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      })),
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Toggle user active status
// @route   PUT /api/auth/users/:id/toggle-active
// @access  Public (should be protected in production)
const toggleUserActive = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    user.isActive = !user.isActive;
    await user.save();

    res.json({
      success: true,
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        userType: user.userType,
        isActive: user.isActive,
      },
    });
  } catch (error) {
    console.error('Toggle user active error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Approve or reject tenant
// @route   PUT /api/auth/users/:id/status
// @access  Public (should be protected in production)
const updateUserStatus = async (req, res) => {
  try {
    const { status } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be pending, approved, or rejected',
      });
    }

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    user.status = status;
    await user.save();

    res.json({
      success: true,
      message: `User ${status === 'approved' ? 'approved' : status === 'rejected' ? 'rejected' : 'status updated'} successfully`,
      user: {
        id: user._id.toString(),
        name: user.name,
        username: user.username,
        email: user.email,
        mobileNumber: user.mobileNumber,
        userType: user.userType,
        status: user.status,
        isActive: user.isActive,
      },
    });
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update manager
// @route   PUT /api/auth/managers/:id
// @access  Public (should be protected in production)
const updateManager = async (req, res) => {
  try {
    const { name, email, mobileNumber, password } = req.body;
    const managerId = req.params.id;

    // Find manager in Manager collection
    let manager = await Manager.findById(managerId);

    if (!manager) {
      return res.status(404).json({
        success: false,
        error: 'Manager not found',
      });
    }

    // Update fields
    if (name) manager.name = name;
    if (email) {
      // Check if email already exists in any collection
      const emailExists = await Promise.all([
        User.findOne({ email: email.toLowerCase(), _id: { $ne: managerId } }),
        Admin.findOne({ email: email.toLowerCase(), _id: { $ne: managerId } }),
        Manager.findOne({ email: email.toLowerCase(), _id: { $ne: managerId } }),
        Security.findOne({ email: email.toLowerCase(), _id: { $ne: managerId } }),
      ]);

      if (emailExists.some(user => user !== null)) {
        return res.status(400).json({
          success: false,
          error: 'Email already exists',
        });
      }
      manager.email = email.toLowerCase();
    }
    if (mobileNumber) manager.mobileNumber = mobileNumber;
    if (password) {
      const bcrypt = require('bcryptjs');
      manager.password = await bcrypt.hash(password, 10);
    }

    // Handle profile picture upload
    if (req.files && req.files.profilePic && req.files.profilePic[0]) {
      const { uploadToCloudinary } = require('../middleware/upload');
      manager.profilePic = await uploadToCloudinary(
        req.files.profilePic[0].buffer,
        'apartment_management/profile_pics'
      );
    }

    // Handle ID proof upload
    if (req.files && req.files.aadhaarFront && req.files.aadhaarFront[0]) {
      const { uploadToCloudinary } = require('../middleware/upload');
      manager.aadhaarCardFrontImage = await uploadToCloudinary(
        req.files.aadhaarFront[0].buffer,
        'apartment_management/id_cards'
      );
    }

    await manager.save();

    res.json({
      success: true,
      message: 'Manager updated successfully',
      manager: {
        id: manager._id.toString(),
        name: manager.name,
        email: manager.email,
        mobileNumber: manager.mobileNumber,
        profilePic: manager.profilePic,
        aadhaarCardFrontImage: manager.aadhaarCardFrontImage,
      },
    });
  } catch (error) {
    console.error('Update manager error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete manager
// @route   DELETE /api/auth/managers/:id
// @access  Public (should be protected in production)
const deleteManager = async (req, res) => {
  try {
    const managerId = req.params.id;

    const manager = await Manager.findById(managerId);

    if (!manager) {
      return res.status(404).json({
        success: false,
        error: 'Manager not found',
      });
    }

    await Manager.findByIdAndDelete(managerId);

    res.json({
      success: true,
      message: 'Manager deleted successfully',
    });
  } catch (error) {
    console.error('Delete manager error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update security staff
// @route   PUT /api/auth/security/:id
// @access  Public (should be protected in production)
const updateSecurity = async (req, res) => {
  try {
    const { name, email, mobileNumber, password } = req.body;
    const securityId = req.params.id;

    // Find security in Security collection
    let security = await Security.findById(securityId);

    if (!security) {
      return res.status(404).json({
        success: false,
        error: 'Security staff not found',
      });
    }

    // Update fields
    if (name) security.name = name;
    if (email) {
      // Check if email already exists in any collection
      const emailExists = await Promise.all([
        User.findOne({ email: email.toLowerCase(), _id: { $ne: securityId } }),
        Admin.findOne({ email: email.toLowerCase(), _id: { $ne: securityId } }),
        Manager.findOne({ email: email.toLowerCase(), _id: { $ne: securityId } }),
        Security.findOne({ email: email.toLowerCase(), _id: { $ne: securityId } }),
      ]);

      if (emailExists.some(user => user !== null)) {
        return res.status(400).json({
          success: false,
          error: 'Email already exists',
        });
      }
      security.email = email.toLowerCase();
    }
    if (mobileNumber) security.mobileNumber = mobileNumber;
    if (password) {
      const bcrypt = require('bcryptjs');
      security.password = await bcrypt.hash(password, 10);
    }

    // Handle profile picture upload
    if (req.files && req.files.profilePic && req.files.profilePic[0]) {
      const { uploadToCloudinary } = require('../middleware/upload');
      security.profilePic = await uploadToCloudinary(
        req.files.profilePic[0].buffer,
        'apartment_management/profile_pics'
      );
    }

    // Handle ID proof upload
    if (req.files && req.files.aadhaarFront && req.files.aadhaarFront[0]) {
      const { uploadToCloudinary } = require('../middleware/upload');
      security.aadhaarCardFrontImage = await uploadToCloudinary(
        req.files.aadhaarFront[0].buffer,
        'apartment_management/id_cards'
      );
    }

    await security.save();

    res.json({
      success: true,
      message: 'Security staff updated successfully',
      security: {
        id: security._id.toString(),
        name: security.name,
        email: security.email,
        mobileNumber: security.mobileNumber,
        profilePic: security.profilePic,
        aadhaarCardFrontImage: security.aadhaarCardFrontImage,
      },
    });
  } catch (error) {
    console.error('Update security error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete security staff
// @route   DELETE /api/auth/security/:id
// @access  Public (should be protected in production)
const deleteSecurity = async (req, res) => {
  try {
    const securityId = req.params.id;

    const security = await Security.findById(securityId);

    if (!security) {
      return res.status(404).json({
        success: false,
        error: 'Security staff not found',
      });
    }

    await Security.findByIdAndDelete(securityId);

    res.json({
      success: true,
      message: 'Security staff deleted successfully',
    });
  } catch (error) {
    console.error('Delete security error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  registerUser,
  registerAdmin,
  loginUser,
  sendOTP,
  verifyOTP,
  forgotPassword,
  resetPassword,
  getCurrentUser,
  getAllUsers,
  toggleUserActive,
  updateUserStatus,
  updateManager,
  deleteManager,
  updateSecurity,
  deleteSecurity,
};

