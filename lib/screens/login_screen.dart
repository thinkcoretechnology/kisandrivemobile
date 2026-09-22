import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_phone_validator.dart';
import '../widgets/kisan_loader.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';
  Future<void> _handleAuth() async {
    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final pass = _passwordController.text.trim();

    if (mobile.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter mobile number and password');
      return;
    }

    final mobileErr = IndianPhoneValidator.validate(mobile);
    if (mobileErr != null) {
      setState(() => _errorMessage = mobileErr);
      return;
    }

    if (_isRegistering) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter First Name and Last Name');
        return;
      }

      if (pass.length < 5) {
        setState(() => _errorMessage = 'Password must be at least 5 characters long');
        return;
      }

      if (pass != _confirmPasswordController.text.trim()) {
        setState(() => _errorMessage = 'Password and Confirm Password do not match');
        return;
      }
    }

    // Check network availability before proceeding
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
      _errorMessage = '';
    });

    bool success;
    if (_isRegistering) {
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      success = await widget.authService.register(fullName, mobile, pass);
    } else {
      success = await widget.authService.login(mobile, pass);
    }

    setState(() => _isLoading = false);

    if (success) {
      widget.onLoginSuccess();
    } else {
      final isOnline = await NetworkService.isNetworkAvailable();
      setState(() => _errorMessage = !isOnline
          ? '📶 No Internet Connection. Please check your network connection and try again.'
          : _isRegistering
              ? 'Registration failed. Mobile number may already exist.'
              : 'Invalid mobile number or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light Theme Background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KisanDrive Brand Logo Header
                Image.asset(
                  'assets/images/kisandrive_logo.png',
                  width: 110,
                  height: 110,
                  errorBuilder: (ctx, err, stack) => const KisanLoader(size: 110, isSpinning: false),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    children: [
                      TextSpan(text: 'Kisan', style: TextStyle(color: Color(0xFF16A34A))),
                      TextSpan(text: 'Drive ', style: TextStyle(color: Color(0xFFCA8A04))),
                      TextSpan(text: 'ERP', style: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'SaaS Agricultural Fleet Management',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Main Form Card (Clean Light Card Design)
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
                        Text(
                          _isRegistering ? '👨‍🌾 Tenant Registration' : '🔐 Sign In to Fleet Portal',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRegistering ? 'Enter your details to create a new fleet account' : 'Enter registered 10-digit mobile number & password',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),

                        if (_errorMessage.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // IF REGISTERING -> FIRST NAME & LAST NAME FIELDS!
                        if (_isRegistering) ...[
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Mobile Number Input
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password Input
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                            floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock, color: AppColors.tealPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                            ),
                          ),
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 12),
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
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.tealPrimary, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tealPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isRegistering ? 'Create KisanDrive Account' : 'Sign In to Account',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle Login / Register Option
                TextButton(
                  onPressed: () => setState(() => _isRegistering = !_isRegistering),
                  child: Text(
                    _isRegistering ? 'Already have an account? Sign In' : "Don't have an account? Register User",
                    style: const TextStyle(color: AppColors.tealPrimary, fontSize: 13, fontWeight: FontWeight.bold),
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
