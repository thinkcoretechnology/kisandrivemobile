import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import 'subscriptions_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;

  const ProfileScreen({super.key, required this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  SubscriptionRecord? _subscription;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false; // False by default -> Show Read-Only Info Card!

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _aadharController;
  late TextEditingController _imageUrlController;

  String _selectedGender = 'Male';
  String _selectedState = 'Tamil Nadu';

  final List<String> _states = [
    'Tamil Nadu',
    'Kerala',
    'Karnataka',
    'Andhra Pradesh',
    'Telangana',
    'Maharashtra',
    'Puducherry',
  ];

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _pincodeController = TextEditingController();
    _aadharController = TextEditingController();
    _imageUrlController = TextEditingController();
    _loadProfileData();
  }

  void _onAuthChanged() {
    if (mounted) {
      _loadProfileData();
    }
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    _nameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _aadharController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final token = widget.authService.token;
    if (token == null) return;

    final user = await ApiService.getProfile(token);
    final sub = await ApiService.getMySubscription(token);

    if (mounted) {
      setState(() {
        _user = user;
        _subscription = sub;

        if (user != null) {
          _nameController.text = user.fullName;
          _selectedGender = user.gender.isNotEmpty ? user.gender : 'Male';
          _addressController.text = user.address;
          _selectedState = user.state.isNotEmpty ? user.state : 'Tamil Nadu';
          _pincodeController.text = user.pincode;
          _aadharController.text = user.aadharCard;
          _imageUrlController.text = user.profileImage;
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _takeCameraPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera, // PHONE CAMERA ONLY!
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _imageUrlController.text = base64Image;
        });

        // Auto-save camera photo change immediately!
        await _saveProfileDataSilently();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking camera photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfileDataSilently() async {
    final token = widget.authService.token;
    if (token == null) return;

    final updatedData = {
      'full_name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : (_user?.fullName ?? ''),
      'gender': _selectedGender,
      'address': _addressController.text.trim(),
      'state': _selectedState,
      'pincode': _pincodeController.text.trim(),
      'aadhar_card': _aadharController.text.trim(),
      'profile_image': _imageUrlController.text.trim(),
    };

    final updatedUser = await ApiService.updateProfile(token, updatedData);
    if (updatedUser != null) {
      await widget.authService.updateCurrentUser(updatedUser);
      setState(() {
        _user = updatedUser;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Profile photo captured & saved from phone camera!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  ImageProvider? _getAvatarImageProvider() {
    final img = _imageUrlController.text.trim();
    if (img.isEmpty) return null;
    if (img.startsWith('data:image')) {
      try {
        final base64Str = img.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return NetworkImage(img);
    }
    return null;
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final token = widget.authService.token;
    if (token == null) return;

    final updatedData = {
      'full_name': _nameController.text.trim(),
      'gender': _selectedGender,
      'address': _addressController.text.trim(),
      'state': _selectedState,
      'pincode': _pincodeController.text.trim(),
      'aadhar_card': _aadharController.text.trim(),
      'profile_image': _imageUrlController.text.trim(),
    };

    final updatedUser = await ApiService.updateProfile(token, updatedData);
    setState(() => _isSaving = false);

    if (updatedUser != null) {
      await widget.authService.updateCurrentUser(updatedUser);
      setState(() {
        _user = updatedUser;
        _isEditing = false; // Return to Read-Only Card view!
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile & Picture updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getTwoInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'TU';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final f = parts[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final s = parts[1].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (f.isNotEmpty && s.isNotEmpty) {
        return (f[0] + s[0]).toUpperCase();
      }
    }
    final clean = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean.isNotEmpty ? clean[0].toUpperCase() : 'TU';
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _getAvatarImageProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Profile & Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Avatar Profile Header Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _takeCameraPhoto, // PHONE CAMERA ONLY!
                              borderRadius: BorderRadius.circular(50),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: AppColors.tealPrimary,
                                    backgroundImage: avatarProvider,
                                    child: avatarProvider != null
                                        ? null
                                        : Center(
                                            child: Text(_getTwoInitials(_user?.fullName), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                                          ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.goldPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(_user?.fullName ?? 'Tractor Owner', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text('Mobile: ${_user?.mobileNumber ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.goldPrimary),
                              ),
                              child: Text(
                                'Role: ${_user?.role ?? "Tractor Owner"}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // READ-ONLY INFORMATION CARD VIEW vs EDIT FORM VIEW
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text('📌 Personal & Address Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = !_isEditing;
                                    });
                                  },
                                  icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 14, color: AppColors.tealPrimary),
                                  label: Text(_isEditing ? 'Cancel' : 'Edit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.tealPrimary)),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 10),

                            // READ-ONLY INFO CARD VIEW (WHEN NOT EDITING)
                            if (!_isEditing) ...[
                              _buildInfoRow('👤 Full Name:', _user?.fullName ?? 'N/A'),
                              _buildInfoRow('👤 Gender:', _user?.gender ?? 'Male'),
                              _buildInfoRow('🏠 Street / Village Address:', _user?.address.isNotEmpty == true ? _user!.address : 'N/A'),
                              _buildInfoRow('MAP State:', _user?.state ?? 'Tamil Nadu'),
                              _buildInfoRow('📍 Pincode:', _user?.pincode.isNotEmpty == true ? _user!.pincode : 'N/A'),
                              _buildInfoRow('🪪 Aadhaar Card Number:', _user?.aadharCard.isNotEmpty == true ? _user!.aadharCard : 'N/A'),
                            ]
                            // EDITABLE FORM VIEW (WHEN EDITING)
                            else ...[
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter Full Name' : null,
                                      decoration: const InputDecoration(labelText: 'Full Name *'),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedGender,
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (val) => setState(() => _selectedGender = val ?? 'Male'),
                                      decoration: const InputDecoration(labelText: 'Gender'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _addressController,
                                      maxLines: 2,
                                      decoration: const InputDecoration(labelText: 'Address / Village'),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedState,
                                      items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                      onChanged: (val) => setState(() => _selectedState = val ?? 'Tamil Nadu'),
                                      decoration: const InputDecoration(labelText: 'State'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _pincodeController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                                      decoration: const InputDecoration(labelText: 'Pincode (6 Digits)'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _aadharController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                                      decoration: const InputDecoration(labelText: 'Aadhaar Card (12 Digits)'),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _saveProfileData,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.tealPrimary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: _isSaving
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text('Save Profile Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Subscription Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text('🏷️ Active Subscription Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => SubscriptionsScreen(authService: widget.authService)),
                                    );
                                    _loadProfileData();
                                  },
                                  icon: const Icon(Icons.card_membership, size: 12),
                                  label: Text(_subscription != null ? 'Change' : 'Subscribe', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.tealPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(50, 30),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            if (_subscription != null) ...[
                              Text(_subscription!.planName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                              const SizedBox(height: 4),
                              Text('Valid until: ${DateFormatter.formatDDMMYYYY(_subscription!.endDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Paid Amount: ₹${_subscription!.subscriptionAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ] else ...[
                              const Text('No Active Subscription Plan found.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
