import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_phone_validator.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({
    super.key,
    required this.authService,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || mobile.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required fields');
      return;
    }

    final mobileErr = IndianPhoneValidator.validate(mobile);
    if (mobileErr != null) {
      setState(() => _errorMessage = mobileErr);
      return;
    }

    // Password validation (Minimum 5 characters)
    if (password.length < 5) {
      setState(() => _errorMessage = 'Password must be at least 5 characters long');
      return;
    }

    // Password & Confirm Password Match Validation
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Password and Confirm Password do not match');
      return;
    }

    // Check Network Availability
    final hasNetwork = await NetworkService.isNetworkAvailable();
    if (!hasNetwork) {
      setState(() {
        _isLoading = false;
        _errorMessage = '📶 No Internet Connection. Please check your network connection and try again.';
      });
      if (mounted) NetworkService.showNoInternetSnackbar(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullName = '$firstName $lastName';
      final res = await widget.authService.register(fullName, mobile, password);
      setState(() => _isLoading = false);

      if (res) {
        widget.onRegisterSuccess();
      } else {
        final isOnline = await NetworkService.isNetworkAvailable();
        setState(() => _errorMessage = !isOnline
            ? '📶 No Internet Connection. Please check your network connection and try again.'
            : 'Mobile number already registered. Please sign in or use another number.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '📶 Network connection failed. Please check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Theme Background
      appBar: AppBar(
        title: const Text('Tenant Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo Accent
                Image.asset(
                  'assets/images/kisandrive_logo.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.agriculture, size: 60, color: AppColors.tealPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create KisanDrive Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Text(
                  'Setup your tractor fleet management tenant profile',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // Card Form Container
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppColors.tealPrimary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // First Name & Last Name Input Fields
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'First Name *',
                                  labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                                  floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                                  hintText: 'e.g. Ram',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  prefixIcon: const Icon(Icons.person, color: AppColors.tealPrimary, size: 20),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Last Name *',
                                  labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                                  floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                                  hintText: 'e.g. Kumar',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.tealPrimary, size: 20),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mobile Number
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mobile Number (10 Digits) *',
                            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                            floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                            hintText: 'e.g. 9952043017',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.phone_android, color: AppColors.tealPrimary, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field (Min 5 chars)
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Password (Min 5 Chars) *',
                            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                            floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.tealPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                            floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock, color: AppColors.tealPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tealPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Create Account & Select Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
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
