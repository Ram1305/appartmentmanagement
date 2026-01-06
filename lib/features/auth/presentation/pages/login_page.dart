import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/user_model.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  UserType? _selectedUserType;

  @override
  void initState() {
    super.initState();
    // Try to get user type from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserType && _selectedUserType == null) {
        setState(() {
          _selectedUserType = args;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get user type from route arguments - only set if not already set
    if (_selectedUserType == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      print('=== LOGIN PAGE INIT ===');
      print('Route arguments: $args');
      print('Arguments type: ${args.runtimeType}');
      if (args is UserType) {
        print('Setting userType to: $args');
        setState(() {
          _selectedUserType = args;
        });
        // Pre-fill email based on user type
        _prefillCredentials(args);
      } else {
        print('No UserType in arguments');
      }
    }
  }

  void _prefillCredentials(UserType userType) {
    // No longer pre-filling credentials - user can enter any email/password
    // The credentials are just for display purposes, any email/password will work
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Prevent double taps
    if (_isLoading) return;
    
    // Unfocus text fields
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Ensure user type is set - if not, try to get it from route arguments
      UserType? userType = _selectedUserType;
      if (userType == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is UserType) {
          userType = args;
          setState(() {
            _selectedUserType = userType;
          });
        } else {
          // Default to user if no type is specified
          userType = UserType.user;
        }
      }
      
      print('=== FRONTEND LOGIN ATTEMPT ===');
      print('Email: ${_emailController.text.trim()}');
      print('UserType: $userType');
      print('UserType.name: ${userType.name}');
      print('Selected UserType: $_selectedUserType');
      
      context.read<AuthBloc>().add(
            LoginEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              userType: userType,
            ),
          );
    }
  }

  void _navigateToDashboard(UserModel user) {
    print('=== NAVIGATE TO DASHBOARD ===');
    print('User name: ${user.name}');
    print('User email: ${user.email}');
    print('User userType: ${user.userType}');
    print('User userType.name: ${user.userType.name}');
    print('User status: ${user.status}');
    
    String route = AppRoutes.login;
    switch (user.userType) {
      case UserType.admin:
        route = AppRoutes.adminDashboard;
        print('Selected route: $route (Admin Dashboard)');
        break;
      case UserType.manager:
        route = AppRoutes.managerDashboard;
        print('Selected route: $route (Manager Dashboard)');
        break;
      case UserType.user:
        route = AppRoutes.userDashboard;
        print('Selected route: $route (User Dashboard)');
        break;
      case UserType.security:
        route = AppRoutes.securityDashboard;
        print('Selected route: $route (Security Dashboard)');
        break;
      default:
        print('WARNING: Unknown userType, defaulting to login');
        route = AppRoutes.login;
    }
    
    print('Navigating to: $route');
    try {
      Navigator.pushReplacementNamed(context, route);
      print('✓ Navigation successful');
    } catch (e) {
      print('✗ Navigation error: $e');
    }
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Please contact your administrator to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('=== LOGIN PAGE STATE CHANGE ===');
          print('State: ${state.runtimeType}');
          
          if (state is AuthAuthenticated) {
            print('✓ Login successful!');
            print('User: ${state.user.name}');
            print('UserType: ${state.user.userType}');
            print('Status: ${state.user.status}');
            setState(() {
              _isLoading = false;
            });
            // Check user status - if pending, show waiting page; if approved, go to dashboard
            if (state.user.status == AccountStatus.pending) {
              Navigator.pushReplacementNamed(context, AppRoutes.waitingApproval);
            } else if (state.user.status == AccountStatus.approved) {
              _navigateToDashboard(state.user);
            } else if (state.user.status == AccountStatus.rejected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account has been rejected. Please contact administrator.'),
                  backgroundColor: AppTheme.errorColor,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else if (state is AuthUnauthenticated) {
            print('User unauthenticated');
            setState(() {
              _isLoading = false;
            });
            // User logged out, already on login page
          } else if (state is AuthError) {
            print('✗ Login error: ${state.message}');
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is AuthLoading) {
            print('Loading...');
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Logo with gradient background
                Container(

                  decoration: BoxDecoration(
                    color: Colors.white, // or AppTheme.primaryColor
                    borderRadius: BorderRadius.circular(10),

                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/appicon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedUserType != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Login Type: ${_getUserTypeName(_selectedUserType!)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      _handleLogin();
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: _isLoading ? null : () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _navigateToForgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading || _isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isLoading ? 0 : 4,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  // Only show registration link for regular users
                  if (_selectedUserType == UserType.user || _selectedUserType == null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            Navigator.pushNamed(context, AppRoutes.userRegistration);
                          },
                          child: const Text('Register as User'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredential(String role, String email, String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$role: $email / $password',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  String _getUserTypeName(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'Admin';
      case UserType.manager:
        return 'Manager';
      case UserType.security:
        return 'Security';
      case UserType.user:
        return 'User';
    }
  }
}

