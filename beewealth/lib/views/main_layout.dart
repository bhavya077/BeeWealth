import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/home_screen.dart';
import 'dashboard/trade_screen.dart';
import 'profile/profile_screen.dart';
import 'ledger/ledger_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TradeScreen(),
    const LedgerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ColorFilter.mode(Colors.black.withOpacity(0.01), BlendMode.dstIn),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16191F).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: Colors.white24,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  items: [
                    _buildNavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'TERMINAL', 0),
                    _buildNavItem(Icons.swap_horiz_outlined, Icons.swap_horiz_rounded, 'TRADE', 1),
                    _buildNavItem(Icons.account_balance_outlined, Icons.account_balance_rounded, 'LEDGER', 2),
                    _buildNavItem(Icons.person_outline, Icons.person_rounded, 'PROFILE', 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(isSelected ? activeIcon : icon, size: 24),
      ),
      label: label,
    );
  }
}
