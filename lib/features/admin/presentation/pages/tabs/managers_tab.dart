import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../core/app_theme.dart';
import '../../../../../core/models/user_model.dart';
import '../../bloc/admin_bloc.dart';

class ManagersTab extends StatelessWidget {
  final AdminLoaded state;

  const ManagersTab({required this.state});

  void _showAddManagerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    File? profilePic;
    File? idProof;
    final ImagePicker picker = ImagePicker();
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminLoaded) {
            // Success - close dialog and show message
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Manager added successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is AdminError) {
            // Error - show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: StatefulBuilder(
          builder: (context, setDialogState) => BlocBuilder<AdminBloc, AdminState>(
            builder: (context, blocState) {
              final isLoading = blocState is AdminLoading;
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Add Manager',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter manager details and upload images',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() {
                          profilePic = File(image.path);
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: profilePic != null ? AppTheme.primaryColor : Colors.grey[300]!,
                              width: 3,
                            ),
                            color: Colors.grey[100],
                          ),
                          child: profilePic != null
                              ? ClipOval(
                                  child: Image.file(
                                    profilePic!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_add_rounded,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                        ),
                        if (profilePic != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
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
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
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
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
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
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email ID',
                    prefixIcon: const Icon(Icons.email, color: AppTheme.primaryColor),
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
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    bool isPasswordVisible = false;
                    return StatefulBuilder(
                      builder: (context, setPasswordState) {
                        return TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setPasswordState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
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
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        idProof = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: idProof != null ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: idProof != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  idProof!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload ID Proof',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID Proof Picture',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      nameController.dispose();
                                      emailController.dispose();
                                      mobileController.dispose();
                                      passwordController.dispose();
                                      Navigator.pop(context);
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter name'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (mobileController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter mobile number'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (emailController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter email ID'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (passwordController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter password'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (passwordController.text.trim().length < 6) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Password must be at least 6 characters'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Dispatch event to add manager
                                      context.read<AdminBloc>().add(
                                        AddManagerEvent(
                                          name: nameController.text.trim(),
                                          email: emailController.text.trim(),
                                          mobileNumber: mobileController.text.trim(),
                                          password: passwordController.text.trim(),
                                          profilePic: profilePic,
                                          idProof: idProof,
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLoading ? Colors.grey : AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Add Manager',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Managers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${state.managers.length} ${state.managers.length == 1 ? 'Manager' : 'Managers'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddManagerDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Manager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.managers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Managers Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first manager to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.managers.length,
                  itemBuilder: (context, index) {
                    final manager = state.managers[index];
                    return _buildUserCard(context, manager, true);
                  },
                ),
        ),
      ],
    );
  }

  void _showEditManagerDialog(BuildContext context, UserModel manager) {
    final nameController = TextEditingController(text: manager.name);
    final emailController = TextEditingController(text: manager.email);
    final mobileController = TextEditingController(text: manager.mobileNumber);
    final passwordController = TextEditingController();
    File? profilePic;
    File? idProof;
    final ImagePicker picker = ImagePicker();
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminLoaded) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Manager updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: StatefulBuilder(
          builder: (context, setDialogState) => BlocBuilder<AdminBloc, AdminState>(
            builder: (context, blocState) {
              final isLoading = blocState is AdminLoading;
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Edit Manager',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update manager details',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setDialogState(() {
                                profilePic = File(image.path);
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: profilePic != null || (manager.profilePic != null && manager.profilePic!.isNotEmpty)
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                    width: 3,
                                  ),
                                  color: Colors.grey[100],
                                ),
                                child: profilePic != null
                                    ? ClipOval(
                                        child: Image.file(
                                          profilePic!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : manager.profilePic != null && manager.profilePic!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              manager.profilePic!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person_add_rounded,
                                                  size: 50,
                                                  color: Colors.grey,
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_add_rounded,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                              ),
                              if (profilePic != null || (manager.profilePic != null && manager.profilePic!.isNotEmpty))
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
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
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Profile Picture',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email ID',
                          prefixIcon: const Icon(Icons.email, color: AppTheme.primaryColor),
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          bool isPasswordVisible = false;
                          return StatefulBuilder(
                            builder: (context, setPasswordState) {
                              return TextField(
                                controller: passwordController,
                                obscureText: !isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password (leave empty to keep current)',
                                  prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setPasswordState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                  ),
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() {
                              idProof = File(image.path);
                            });
                          }
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: idProof != null || (manager.aadhaarCardFrontImage != null && manager.aadhaarCardFrontImage!.isNotEmpty)
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: idProof != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        idProof!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : manager.aadhaarCardFrontImage != null && manager.aadhaarCardFrontImage!.isNotEmpty
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            manager.aadhaarCardFrontImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.upload_file,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Tap to upload ID Proof',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to upload ID Proof',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID Proof Picture',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      nameController.dispose();
                                      emailController.dispose();
                                      mobileController.dispose();
                                      passwordController.dispose();
                                      Navigator.pop(context);
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter name'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (mobileController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter mobile number'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (emailController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter email ID'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      context.read<AdminBloc>().add(
                                        UpdateManagerEvent(
                                          managerId: manager.id,
                                          name: nameController.text.trim(),
                                          email: emailController.text.trim(),
                                          mobileNumber: mobileController.text.trim(),
                                          password: passwordController.text.trim().isNotEmpty
                                              ? passwordController.text.trim()
                                              : null,
                                          profilePic: profilePic,
                                          idProof: idProof,
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLoading ? Colors.grey : AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Update Manager',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteManagerDialog(BuildContext context, UserModel manager) {
    showDialog(
      context: context,
      builder: (context) => BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminLoaded) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Manager deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, blocState) {
            final isLoading = blocState is AdminLoading;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Delete Manager?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete ${manager.name}?',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AdminBloc>().add(
                                DeleteManagerEvent(managerId: manager.id),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, bool isManager) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: user.isActive
              ? [
                  Colors.white,
                  Colors.white,
                  AppTheme.primaryColor.withOpacity(0.03),
                ]
              : [
                  Colors.grey[50]!,
                  Colors.grey[50]!,
                  Colors.grey[100]!,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: user.isActive
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: user.isActive
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
                // Profile Picture
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: user.isActive
                              ? [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.7),
                                ]
                              : [
                                  Colors.grey[400]!,
                                  Colors.grey[500]!,
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (user.isActive
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400]!)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: user.profilePic != null && user.profilePic!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user.profilePic!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      user.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    if (user.isActive)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: user.isActive
                                    ? AppTheme.textColor
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user.status == AccountStatus.approved
                                  ? Colors.green.withOpacity(0.15)
                                  : user.status == AccountStatus.pending
                                      ? Colors.orange.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: user.status == AccountStatus.approved
                                    ? Colors.green[700]
                                    : user.status == AccountStatus.pending
                                        ? Colors.orange[700]
                                        : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.mobileNumber,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Actions Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Active Toggle
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Switch(
                        value: user.isActive,
                        onChanged: (value) {
                          context.read<AdminBloc>().add(
                                ToggleUserActiveEvent(user.id),
                              );
                        },
                        activeColor: AppTheme.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        color: user.isActive ? Colors.green[700] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Edit and Delete Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        InkWell(
                          onTap: () => _showEditManagerDialog(context, user),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        InkWell(
                          onTap: () => _showDeleteManagerDialog(context, user),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}
