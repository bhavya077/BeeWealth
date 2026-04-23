import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';
import '../../models/app_models.dart';

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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Aura
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentityCard(user),
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('FINANCIAL ARCHITECTURE'),
                  const SizedBox(height: 16),
                  _buildManagementTile(
                    'INSTITUTIONAL SETTLEMENT',
                    'Configure bank routing and identifiers',
                    Icons.account_balance_outlined,
                    () => _showBankingModal(context),
                  ),
                  const SizedBox(height: 12),
                  _buildManagementTile(
                    'DIGITAL ASSET ROUTING',
                    'Manage UPI and SDR settlement indices',
                    Icons.cell_tower_rounded,
                    () => _showUPIModal(context),
                  ),

                  const SizedBox(height: 48),
                  _buildSectionHeader('SYSTEMS CONTROL'),
                  const SizedBox(height: 16),
                  _buildSecurityAction(
                    'SESSION TERMINATION',
                    'Securely vault assets and end session',
                    Icons.power_settings_new_rounded,
                    AppColors.error,
                    () {
                      auth.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 64),
                  _buildSystemDiagnostics(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 3),
      ),
    );
  }

  Widget _buildIdentityCard(User? user) {
    return FadeIn(
      duration: const Duration(seconds: 1),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name.toUpperCase() ?? 'IDENTIFIED CLIENT',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'INVESTMENT ACCOUNT VERIFIED',
                        style: TextStyle(color: AppColors.success.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardStat('UID', user?.membershipId ?? '---'),
                _buildCardStat('ROLE', user?.role.toUpperCase() ?? 'GUEST'),
                _buildCardStat('STATUS', 'ACTIVE'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showBankingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalWrapper(
        title: 'BANKING INFRASTRUCTURE',
        icon: Icons.account_balance_outlined,
        children: [
          _buildModalField('Bank Name', _bankNameController, Icons.account_balance_outlined),
          const Divider(color: Colors.white10, height: 32),
          _buildModalField('Account No.', _accountNumberController, Icons.tag_rounded),
          const Divider(color: Colors.white10, height: 32),
          _buildModalField('IFSC Code', _ifscController, Icons.qr_code_rounded),
        ],
      ),
    );
  }

  void _showUPIModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalWrapper(
        title: 'SETTLEMENT INDICES',
        icon: Icons.cell_tower_rounded,
        children: [
          _buildModalField('UPI Identifier', _upiIdController, Icons.alternate_email_rounded),
          const Divider(color: Colors.white10, height: 32),
          _buildModalField('Mobile Index', _upiNumberController, Icons.phone_iphone_rounded),
        ],
      ),
    );
  }

  Widget _buildModalWrapper({required String title, required IconData icon, required List<Widget> children}) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121418),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ...children,
                  const SizedBox(height: 48),
                  CustomButton(
                    text: 'COMMIT DATABASE UPDATES',
                    onPressed: () {
                      _updateProfile();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 20), // Extra space to clear keyboard suggestions
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalField(String label, TextEditingController controller, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white12, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.only(top: 6)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityAction(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.6), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemDiagnostics() {
    return Center(
      child: Column(
        children: [
          const Text('TERMINAL DIAGNOSTICS OA-V1.0', style: TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDiagDot(Colors.green),
              const SizedBox(width: 8),
              const Text('SECURE CONNECTION: ACTIVE', style: TextStyle(color: Colors.white10, fontSize: 7, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagDot(Color color) {
    return Container(width: 4, height: 4, decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle));
  }
}

class _DataPoint {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  _DataPoint(this.label, this.controller, this.icon);
}
