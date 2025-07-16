import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_login_screen.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Temporarily hold user details until email verified
  String? _tempUid;
  String? _tempName;
  String? _tempRegNo;
  String? _tempEmail;
  String? _tempPhone;
  String? _tempYear;

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();

    setState(() => _isLoading = true);

    try {
      List<String> signInMethods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        _showErrorDialog(
            'The email address is already registered. Please login or use a different email.');
        setState(() => _isLoading = false);
        return;
      }

      final name = _nameController.text.trim();
      final regNo = _regNoController.text.trim().toUpperCase();
      final phone = _phoneController.text.trim();
      final year = _yearController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Store details temporarily until verified
      _tempUid = uid;
      _tempName = name;
      _tempRegNo = regNo;
      _tempEmail = email;
      _tempPhone = phone;
      _tempYear = year;

      if (!mounted) return;

      // Show dialog instructing user to verify email
      _showVerifyEmailDialog();
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Registration failed. Please try again.');
    } catch (e) {
      _showErrorDialog('Unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailVerifiedAndSave() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // reload user to get updated emailVerified status
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      // Save user info to Firestore now
      await FirebaseFirestore.instance.collection('students').doc(_tempUid).set({
        'uid': _tempUid,
        'name': _tempName,
        'email': _tempEmail,
        'regNo': _tempRegNo,
        'phone': _tempPhone,
        'year': _tempYear,
      });

      _showSuccessDialog(
          'Email verified successfully! You can now login.');

      // Clear temp data
      _tempUid = null;
      _tempName = null;
      _tempRegNo = null;
      _tempEmail = null;
      _tempPhone = null;
      _tempYear = null;

      // Log user out for fresh login
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
      );
    } else {
      _showErrorDialog(
          'Your email is not verified yet. Please check your inbox and verify your email.');
    }
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: const Text(
            'A verification email has been sent to your email address. Please verify your email and then click "I have verified" below.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              await _checkEmailVerifiedAndSave();
              setState(() => _isLoading = false);
            },
            child: const Text('I have verified'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      bool obscureText, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        Widget? suffixIcon,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator ??
              (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Registration"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Name', Icons.person, false),
              const SizedBox(height: 15),
              _buildTextField(
                  _regNoController, 'Register Number', Icons.confirmation_number, false),
              const SizedBox(height: 15),
              _buildTextField(
                _emailController,
                'Email',
                Icons.email,
                false,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Email';
                  }
                  if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _phoneController,
                'Phone',
                Icons.phone,
                false,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Phone';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(_yearController, 'Year', Icons.school, false),
              const SizedBox(height: 15),
              _buildTextField(
                _passwordController,
                'Password',
                Icons.lock,
                !_showPassword,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon:
                  Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _confirmPasswordController,
                'Confirm Password',
                Icons.lock,
                !_showConfirmPassword,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,  // <-- put color here inside TextStyle
                  ),
                ),

              ),
              // ... inside the ListView children, after the ElevatedButton for Register:

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already a user?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
