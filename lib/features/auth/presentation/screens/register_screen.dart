import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/bloc/auth/auth_state.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserType _selectedUserType = UserType.client;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.isAuthenticated) {
          if (_selectedUserType == UserType.serviceProvider) {
            await _showProviderDetailsDialog(context, state.userId!);
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
        if (!state.isLoading && state.error == null && !state.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to get started',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildUserTypeSelector(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        context: context,
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        context: context,
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
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
                      _buildTextField(
                        context: context,
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        context: context,
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        context: context,
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Confirm your password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return Column(
                            children: [
                              if (state.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    state.error!,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: state.isLoading ? null : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthBloc>().add(
                                            RegisterRequested(
                                              name: _nameController.text,
                                              email: _emailController.text,
                                              phone: _phoneController.text,
                                              password: _passwordController.text,
                                              userType: _selectedUserType,
                                            ),
                                          );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: state.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                    'Sign Up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeOption(UserType.client),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserTypeOption(UserType.serviceProvider),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeOption(UserType type) {
    final isSelected = _selectedUserType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            type == UserType.client ? 'Client' : 'Service Provider',
            style: GoogleFonts.poppins(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: isPassword
                ? IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () {},
                  )
                : null,
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
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Future<void> _showProviderDetailsDialog(BuildContext context, String userId) async {
    final _idNumberController = TextEditingController();
    List<XFile> _pickedFiles = [];
    final picker = ImagePicker();
    bool submitting = false;
    String? error;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Complete Provider Profile', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'ID Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Upload at least 2 ID Documents'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._pickedFiles.map((file) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _pickedFiles.remove(file);
                              });
                            },
                          ),
                        ],
                      )),
                      if (_pickedFiles.length < 5)
                        GestureDetector(
                          onTap: () async {
                            final picked = await picker.pickMultiImage();
                            if (picked != null && picked.isNotEmpty) {
                              setState(() {
                                _pickedFiles.addAll(picked.take(5 - _pickedFiles.length));
                              });
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (_idNumberController.text.isEmpty || _pickedFiles.length < 2) {
                                    setState(() => error = 'Please provide ID number and at least 2 documents.');
                                    return;
                                  }
                                  setState(() {
                                    submitting = true;
                                    error = null;
                                  });
                                  // Prepare multipart request
                                  var request = http.MultipartRequest('POST', Uri.parse('https://your-backend-url.com/api/provider/create'));
                                  request.fields['userId'] = userId;
                                  request.fields['idNumber'] = _idNumberController.text;
                                  for (var i = 0; i < _pickedFiles.length; i++) {
                                    request.files.add(await http.MultipartFile.fromPath('idDocs', _pickedFiles[i].path));
                                  }
                                  // TODO: Add auth header if needed
                                  var response = await request.send();
                                  if (response.statusCode == 200) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider profile completed!'), backgroundColor: Colors.green));
                                  } else {
                                    setState(() => error = 'Failed to submit provider details.');
                                  }
                                  setState(() => submitting = false);
                                },
                          child: submitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 