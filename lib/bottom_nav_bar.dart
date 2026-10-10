// ignore_for_file: file_names, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Focus.dart';
import 'Home.dart';
import 'Nest.dart';

class LifeNestNavBar extends StatelessWidget {
  const LifeNestNavBar({
    super.key,
    required this.currentTab,
    this.onTabSelected,
    this.onAdd,
  });

  /// 0: Home, 1: Focus, 2: Nest, 3: Budget
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onAdd;

  static void showBudget(BuildContext context) => _showBudgetSheet(context);

  void _onItemTapped(BuildContext context, int target) {
    if (target == currentTab) return;
    if (onTabSelected != null) {
      onTabSelected!(target);
      return;
    }

    switch (target) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        if (currentTab == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FocusScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FocusScreen()),
          );
        }
        break;
      case 2:
        if (currentTab == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NestScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NestScreen()),
          );
        }
        break;
      case 3:
        _showBudgetSheet(context);
        break;
    }
  }

  void _handleAdd(BuildContext context) {
    if (onAdd != null) {
      onAdd!();
    } else {
      _showAddSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset : 14,
      ),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFFEFEDE7), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14382A).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: currentTab == 0,
                onTap: () => _onItemTapped(context, 0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
                label: 'Focus',
                selected: currentTab == 1,
                onTap: () => _onItemTapped(context, 1),
              ),
            ),
            _CenterAddButton(
              onTap: () => _handleAdd(context),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.eco_outlined,
                activeIcon: Icons.eco_rounded,
                label: 'Nest',
                selected: currentTab == 2,
                onTap: () => _onItemTapped(context, 2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Budget',
                selected: currentTab == 3,
                onTap: () => _onItemTapped(context, 3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF7EF),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBDD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF2F6B4A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Budget',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16402B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF5E6E63)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Keep track of everyday expenses, subscriptions, bills, and renewals in one calm place.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  color: const Color(0xFF6B7F73),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE9E3D6)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF2F6B4A),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All subscriptions and bills are up to date.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16402B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showAddSheet(BuildContext context) {
    const options = <(IconData, String)>[
      (Icons.photo_camera_outlined, 'Photos'),
      (Icons.description_outlined, 'Documents'),
      (Icons.link_rounded, 'Links'),
      (Icons.menu_book_outlined, 'Notes'),
      (Icons.location_on_outlined, 'Places'),
      (Icons.lightbulb_outline_rounded, 'Ideas'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF7EF),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add anything',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16402B),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (final o in options)
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: SizedBox(
                        width: 92,
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEBDD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(o.$1, color: const Color(0xFF16402B)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              o.$2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16402B),
                              ),
                            ),
                          ],
                        ),
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

class _CenterAddButton extends StatelessWidget {
  const _CenterAddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Center(
        child: Material(
          color: const Color(0xFF16402B),
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: const Color(0x4016402B),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _activeColor = Color(0xFF16402B);
  static const _inactiveColor = Color(0xFF5E6E63);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _activeColor : _inactiveColor;
    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? activeIcon : icon,
            size: 25,
            color: color,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
