import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import 'role_login_screen.dart';
import '../admin/admin_control_room_screen.dart';
import '../../core/services/auth_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Top Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNavy.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        size: 34,
                        color: AppColors.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Smart Campus Transport",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Select your role to access your personalized transport portal",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ROLE CARD 1: DRIVER LOGIN
              _RoleSelectionCard(
                title: "DRIVER LOGIN",
                subtitle: "Manage your trips and navigate safely.",
                badgeText: "Operations & Navigation",
                icon: Icons.directions_bus_rounded,
                accentColor: const Color(0xFF1E3A8A), // Deep Navy
                iconBgColor: const Color(0xFFDBEAFE),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RoleLoginScreen(role: UserRole.driver),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ROLE CARD 2: STUDENT LOGIN
              _RoleSelectionCard(
                title: "STUDENT LOGIN",
                subtitle: "Know exactly when your assigned bus is arriving.",
                badgeText: "Live ETA & Attendance",
                icon: Icons.school_rounded,
                accentColor: AppColors.primaryBlue, // Royal Blue
                iconBgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RoleLoginScreen(role: UserRole.student),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ROLE CARD 3: PARENT LOGIN
              _RoleSelectionCard(
                title: "PARENT LOGIN",
                subtitle: "Stay informed about your child's transport and safety.",
                badgeText: "Child Journey Monitoring",
                icon: Icons.family_restroom_rounded,
                accentColor: const Color(0xFF0D9488), // Teal
                iconBgColor: const Color(0xFFCCFBF1),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RoleLoginScreen(role: UserRole.guardian),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Administrator Access Shortcut
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final adminUser = AuthService().demoAccounts.firstWhere(
                          (u) => u.role == UserRole.superAdmin,
                        );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminControlRoomScreen(admin: adminUser),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                  label: const Text(
                    "Administrator Control Room",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

