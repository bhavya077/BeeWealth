import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _upiNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _bankNameController.text = user.bankName ?? '';
      _accountNumberController.text = user.accountNumber ?? '';
      _ifscController.text = user.ifscCode ?? '';
      _upiIdController.text = user.upiId ?? '';
      _upiNumberController.text = user.upiNumber ?? '';
    }
  }

  Future<void> _updateProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile({
      'bank_name': _bankNameController.text.trim(),
      'account_number': _accountNumberController.text.trim(),
      'ifsc_code': _ifscController.text.trim(),
      'upi_id': _upiIdController.text.trim(),
      'upi_number': _upiNumberController.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Profile updated successfully' : (auth.error ?? 'Update failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withAlpha(20),
                      child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 0.5),
                      ),
                      child: Text(
                        user?.role.toUpperCase() ?? 'USER',
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'BANK DETAILS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                children: [
                  CustomTextField(label: 'Bank Name', controller: _bankNameController, prefixIcon: Icons.account_balance),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Account Number', controller: _accountNumberController, prefixIcon: Icons.numbers),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'IFSC Code', controller: _ifscController, prefixIcon: Icons.code),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'UPI DETAILS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                children: [
                  CustomTextField(label: 'UPI ID', controller: _upiIdController, prefixIcon: Icons.alternate_email),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'UPI Number', controller: _upiNumberController, prefixIcon: Icons.phone_android),
                ],
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'UPDATE PROFILE',
              isLoading: auth.isLoading,
              onPressed: _updateProfile,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
