import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram/services/auth_service.dart';
import 'package:instagram/screens/home_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  _PhoneVerificationScreenState createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.verifyPhoneNumber(_phoneController.text);
        setState(() {
          _codeSent = true;
        });
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.verifyOTP(_otpController.text);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (error) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_codeSent) ...[  // Phone number input
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number (e.g. +91XXXXXXXXXX)',
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
                        prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        // Check for E.164 format: +[country code][number]
                        final phoneRegExp = RegExp(r'^\+[1-9]\d{1,14}$');
                        if (!phoneRegExp.hasMatch(value)) {
                          return 'Please enter a valid phone number with country code (e.g. +91XXXXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                  ] else ...[  // OTP input
                    TextFormField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        hintText: 'Enter OTP',
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
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP must be 6 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : (_codeSent ? _verifyOTP : _verifyPhone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_codeSent ? 'Verify OTP' : 'Send OTP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}