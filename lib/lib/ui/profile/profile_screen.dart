import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  late UserProfile _currentProfile;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentYellow = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE FROM MYSQL
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getUserProfile();

      if (profile != null) {
        _currentProfile = profile;

        _nameController.text = profile.name;
        _phoneController.text = profile.phoneNumber;
        _addressController.text = profile.address;
        _emailController.text = profile.email;
      } else {
        final user = FirebaseAuth.instance.currentUser;

        _currentProfile = UserProfile(
          uid: user?.uid ?? '',
          name: '',
          phoneNumber: '',
          address: '',
          email: user?.email ?? '',
        );

        _emailController.text = _currentProfile.email;
      }
    } catch (e) {
      debugPrint('PROFILE SCREEN LOAD ERROR: $e');

      final user = FirebaseAuth.instance.currentUser;

      _currentProfile = UserProfile(
        uid: user?.uid ?? '',
        name: '',
        phoneNumber: '',
        address: '',
        email: user?.email ?? '',
      );

      _emailController.text = _currentProfile.email;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  // ============================================================
  // SAVE PROFILE TO MYSQL
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final updatedProfile = UserProfile(
        uid: _currentProfile.uid,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: user?.email ?? _emailController.text.trim(),
      );

      await _profileService.saveUserProfile(updatedProfile);

      _currentProfile = updatedProfile;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    } catch (e) {
      debugPrint('PROFILE SCREEN SAVE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryGreen,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 20),

            _buildTextField('Full Name', Icons.person_outline, _nameController),

            const SizedBox(height: 16),

            _buildTextField(
              'Phone Number',
              Icons.phone_outlined,
              _phoneController,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              'Delivery Address',
              Icons.home_outlined,
              _addressController,
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              'Email',
              Icons.email_outlined,
              _emailController,
              readOnly: true,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SAVE PROFILE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }
}
