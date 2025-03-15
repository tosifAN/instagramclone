import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'phone_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _authService = AuthService();
  
  String _errorMessage = '';
  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    print('\n📝 Opening Sign Up Screen...');
  }

  Future<void> _selectImage() async {
    print('\n📸 Opening image picker...');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      print('✅ Profile picture selected');
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      print('❌ No image selected');
    }
  }

  Future<void> _handleSignup() async {
    print('\n🔐 Validating signup form...');
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      print('✅ Form validation passed');

      try {
        print('👤 Creating new account...');
        await _authService.signUpWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          profileImage: _imageFile,
        );
        
        print('🏠 Navigating to Home Screen...');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (error) {
        print('❌ Signup error: $error');
        setState(() {
          _errorMessage = error.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('⚠️ Form validation failed - please check your inputs');
    }
  }

  @override
  void dispose() {
    print('👋 Closing Sign Up Screen\n');
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Instagram',
                  style: TextStyle(
                    fontFamily: 'Billabong',
                    fontSize: 48,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) 
                          : null,
                        child: _imageFile == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _selectImage,
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneVerificationScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Verify Phone Number',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                        ),
                        onChanged: (_) {
                          print('📝 Typing email...');
                        },
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                        ),
                        onChanged: (_) {
                          print('🔑 Typing password...');
                        },
                        obscureText: true,
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                        ),
                        onChanged: (_) {
                          print('👤 Typing username...');
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          hintText: 'Bio',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.info_outline, color: Colors.grey[600]),
                        ),
                        onChanged: (_) {
                          print('✍️ Typing bio...');
                        },
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign up'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              print('\n🔄 Navigating to Login Screen...');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
