import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../../../admin/presentation/bloc/admin_bloc.dart';

class UserRegistrationPage extends StatefulWidget {
  final bool fromAdmin;
  
  const UserRegistrationPage({
    super.key,
    this.fromAdmin = false,
  });

  @override
  State<UserRegistrationPage> createState() => _UserRegistrationPageState();
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ImageType {
  profilePicture,
  aadhaarFront,
  aadhaarBack,
  panCard,
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _secondaryMobileController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _totalOccupantsController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _obscurePassword = true;

  Gender? _gender;
  FamilyType? _familyType;
  File? _profilePicture;
  File? _aadhaarFrontImage;
  File? _aadhaarBackImage;
  File? _panCardImage;
  bool _isEmailVerified = false;
  bool _isOtpSent = false;

  final ImagePicker _picker = ImagePicker();
  int _currentStep = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _secondaryMobileController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _totalOccupantsController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceModal(ImageType imageType) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery, imageType);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera, imageType);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, ImageType imageType) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        switch (imageType) {
          case ImageType.profilePicture:
            _profilePicture = File(image.path);
            break;
          case ImageType.aadhaarFront:
            _aadhaarFrontImage = File(image.path);
            break;
          case ImageType.aadhaarBack:
            _aadhaarBackImage = File(image.path);
            break;
          case ImageType.panCard:
            _panCardImage = File(image.path);
            break;
        }
      });
    }
  }

  void _sendOtp() {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email address', isError: true);
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }
    // Show OTP field immediately when verify is clicked
    setState(() {
      _isOtpSent = true;
    });
    context.read<AuthBloc>().add(SendOtpEvent(email: _emailController.text.trim()));
  }

  void _verifyOtp() {
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter the OTP', isError: true);
      return;
    }
    context.read<AuthBloc>().add(
          VerifyOtpEvent(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
          ),
        );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && 
        _familyType != null && 
        _gender != null && 
        _isEmailVerified) {
      // Note: Password is required for registration but not stored in UserModel
      // You may need to add a password field to the registration form
      context.read<AuthBloc>().add(
        RegisterUserEvent(
          name: _usernameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          secondaryMobileNumber: _secondaryMobileController.text.trim().isEmpty
              ? null
              : _secondaryMobileController.text.trim(),
          gender: _gender,
          userType: UserType.user,
          familyType: _familyType,
          aadhaarCard: _aadhaarController.text.trim().isEmpty
              ? null
              : _aadhaarController.text.trim(),
          panCard: _panController.text.trim().isEmpty
              ? null
              : _panController.text.trim(),
          totalOccupants: _totalOccupantsController.text.trim().isEmpty
              ? null
              : int.tryParse(_totalOccupantsController.text.trim()),
          profilePicPath: _profilePicture?.path,
          aadhaarFrontPath: _aadhaarFrontImage?.path,
          aadhaarBackPath: _aadhaarBackImage?.path,
          panCardImagePath: _panCardImage?.path,
        ),
      );
    } else {
      String errorMessage = '';
      if (_familyType == null) {
        errorMessage = 'Please select Tenant Type';
      } else if (_gender == null) {
        errorMessage = 'Please select Gender';
      } else if (!_isEmailVerified) {
        errorMessage = 'Please verify your email address';
      }
      _showSnackBar(errorMessage, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (widget.fromAdmin) {
              // Show success message before navigating
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User registered successfully!'),
                  backgroundColor: AppTheme.primaryColor,
                  duration: Duration(seconds: 2),
                ),
              );
              // Trigger reload of users before navigating back
              context.read<AdminBloc>().add(LoadAllUsersEvent());
              // Navigate back to admin dashboard after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context);
                }
              });
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
            }
          } else if (state is AuthError) {
            _showSnackBar(state.message, isError: true);
          } else if (state is OtpSent) {
            setState(() => _isOtpSent = true);
            _showSnackBar('OTP sent to your email', isError: false);
          } else if (state is OtpVerified) {
            setState(() {
              _isEmailVerified = true;
              _isOtpSent = true; // Keep OTP field visible but show success
            });
            _showSnackBar('Email verified successfully!', isError: false);
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              // expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress Indicator
                      // _buildProgressIndicator(),
                      // const SizedBox(height: 32),

                      // Personal Information Section
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _buildProfilePicturePicker(),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Full Name',
                            icon: Icons.person_rounded,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildEmailWithOtp(),
                          if (_isOtpSent && !_isEmailVerified) ...[
                            const SizedBox(height: 20),
                            _buildOtpField(),
                          ],
                          if (_isEmailVerified) ...[
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter password';
                              if (value!.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter mobile number';
                              if (value!.length != 10) return 'Enter valid 10-digit number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _secondaryMobileController,
                            label: 'Secondary Mobile (Optional)',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            isOptional: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tenant Details Section
                      _buildSectionCard(
                        title: 'Tenant Details',
                        icon: Icons.home_rounded,
                        children: [
                          _buildGenderSelection(),
                          const SizedBox(height: 20),
                          _buildFamilyTypeSelection(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _totalOccupantsController,
                            label: 'Total Occupants',
                            icon: Icons.people_rounded,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter total occupants';
                              final num = int.tryParse(value!);
                              if (num == null || num < 1) return 'Enter valid number';
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Documents Section
                      _buildSectionCard(
                        title: 'Identity Documents',
                        icon: Icons.badge_rounded,
                        children: [
                          _buildTextField(
                            controller: _aadhaarController,
                            label: 'ID Card Number',
                            icon: Icons.credit_card_rounded,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter ID card number';
                              if (value!.length < 5) return 'ID card number must be at least 5 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildImagePicker(
                                  'Identity Card Front',
                                  _aadhaarFrontImage,
                                  ImageType.aadhaarFront,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildImagePicker(
                                  'Identity Card Back',
                                  _aadhaarBackImage,
                                  ImageType.aadhaarBack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _panController,
                            label: 'PAN Number',
                            icon: Icons.account_balance_wallet_rounded,
                            maxLength: 10,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter PAN number';
                              if (value!.length != 10) return 'PAN must be 10 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildImagePicker(
                            'PAN Card Image',
                            _panCardImage,
                            ImageType.panCard,
                            isFullWidth: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Register Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: state is AuthLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProgressStep(1, 'Personal', _currentStep >= 0),
              Expanded(child: _buildProgressLine(_currentStep >= 1)),
              _buildProgressStep(2, 'Tenant', _currentStep >= 1),
              Expanded(child: _buildProgressLine(_currentStep >= 2)),
              _buildProgressStep(3, 'Documents', _currentStep >= 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppTheme.primaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppTheme.primaryColor : Colors.grey[300],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
    bool isOptional = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (Optional)' : ''),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        counterText: '',
      ),
      validator: isOptional ? null : validator,
    );
  }

  Widget _buildEmailWithOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isEmailVerified,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_rounded, color: AppTheme.primaryColor),
            suffixIcon: _isEmailVerified
                ? Container(
                    margin: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.verified,
                      color: Colors.green[600],
                      size: 24,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
            filled: true,
            fillColor: _isEmailVerified ? Colors.green[50] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isEmailVerified ? Colors.green : Colors.grey[300]!,
                width: _isEmailVerified ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isEmailVerified ? Colors.green : AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter email';
            if (!value!.contains('@')) return 'Enter valid email';
            return null;
          },
        ),
        if (_isEmailVerified) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email verified successfully',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOtpField() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'OTP sent to ${_emailController.text}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
                  hintText: 'Enter 6-digit code',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _verifyOtp,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.verified_user_rounded),
                  label: Text(isLoading ? 'Verifying...' : 'Verify OTP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () {
                    setState(() {
                      _isOtpSent = false;
                      _otpController.clear();
                    });
                    _sendOtp();
                  },
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption('Male', Gender.male, Icons.male_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption('Female', Gender.female, Icons.female_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption('Other', Gender.other, Icons.transgender_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, Gender value, IconData icon) {
    final isSelected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tenant Type',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFamilyOption('Family', FamilyType.family, Icons.family_restroom_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFamilyOption('Bachelor', FamilyType.bachelor, Icons.person_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFamilyOption(String label, FamilyType value, IconData icon) {
    final isSelected = _familyType == value;
    return InkWell(
      onTap: () => setState(() => _familyType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    String label,
    File? image,
    ImageType imageType, {
    bool isFullWidth = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showImageSourceModal(imageType),
          child: Container(
            height: isFullWidth ? 160 : 140,
            width: isFullWidth ? double.infinity : 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image != null ? AppTheme.primaryColor : Colors.grey[300]!,
                width: 2,
                style: image != null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          image,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_rounded,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicturePicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImageSourceModal(ImageType.profilePicture),
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _profilePicture != null
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                      width: 3,
                    ),
                    color: Colors.grey[100],
                  ),
                  child: _profilePicture != null
                      ? ClipOval(
                          child: Image.file(
                            _profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person_add_rounded,
                          size: 50,
                          color: Colors.grey,
                        ),
                ),
                if (_profilePicture != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showImageSourceModal(ImageType.profilePicture),
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(
              _profilePicture != null ? 'Change Photo' : 'Add Profile Photo',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
