import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import '../core/constants/app_colors.dart';

class RoleSwitcherBar extends StatelessWidget {
  final UserRole currentRole;
  final Function(UserRole) onRoleSelected;

  const RoleSwitcherBar({
    super.key,
    required this.currentRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.secondaryNavy,
        border: Border(bottom: BorderSide(color: AppColors.lightNavy)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.accentCyan, size: 18),
            const SizedBox(width: 8),
            const Text(
              "ACTIVE ROLE:",
              style: TextStyle(
                color: AppColors.accentCyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            ...UserRole.values.map((role) {
              final isSelected = role == currentRole;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(role.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.lightNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      AuthService().switchDemoRole(role);
                      onRoleSelected(role);
                    }
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

