import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../driver/driver_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';

class RoleLoginScreen extends StatefulWidget {
  final UserRole role;

  const RoleLoginScreen({super.key, required this.role});

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prefillDefaultCredentials();
  }

  void _prefillDefaultCredentials() {
    switch (widget.role) {
      case UserRole.driver:
        _emailController.text = 'ravi.driver@campus.edu';
        _passwordController.text = 'password123';
        break;
      case UserRole.student:
        _emailController.text = 'aditya.student@campus.edu';
        _passwordController.text = 'password123';
        break;
      case UserRole.guardian:
        _emailController.text = 'satya.parent@campus.edu';
        _passwordController.text = 'password123';
        break;
      default:
        _emailController.text = 'admin@campus.edu';
        _passwordController.text = 'admin123';
    }
  }

  String get _roleTitle {
    switch (widget.role) {
      case UserRole.driver:
        return "Welcome Back, Driver";
      case UserRole.student:
        return "Track Your College Bus";
      case UserRole.guardian:
        return "Your Child's Journey, At a Glance";
      default:
        return "Transportation Login";
    }
  }

  String get _roleSubtitle {
    switch (widget.role) {
      case UserRole.driver:
        return "Manage your trips and navigate safely.";
      case UserRole.student:
        return "Know exactly when your assigned bus is arriving.";
      case UserRole.guardian:
        return "Stay informed about your child's transport and safety.";
      default:
        return "Enter your authenticated campus credentials.";
    }
  }

  IconData get _roleIcon {
    switch (widget.role) {
      case UserRole.driver:
        return Icons.directions_bus_rounded;
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.guardian:
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color get _accentColor {
    switch (widget.role) {
      case UserRole.driver:
        return const Color(0xFF1E3A8A); // Deep Navy
      case UserRole.student:
        return AppColors.primaryBlue; // Royal Blue
      case UserRole.guardian:
        return const Color(0xFF0D9488); // Teal
      default:
        return AppColors.primaryNavy;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.loginWithRole(
      email: _emailController.text,
      password: _passwordController.text,
      expectedRole: widget.role,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      // Navigate to the role's tailored dashboard
      Widget destination;
      switch (widget.role) {
        case UserRole.driver:
          destination = DriverDashboardScreen(driver: result.user!);
          break;
        case UserRole.student:
          destination = StudentDashboardScreen(student: result.user!);
          break;
        case UserRole.guardian:
          destination = ParentDashboardScreen(guardian: result.user!);
          break;
        default:
          destination = DriverDashboardScreen(driver: result.user!);
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      // Display failure or role mismatch
      setState(() {
        _errorMessage = result.error ?? 'Authentication failed. Please verify credentials.';
      });
      _showErrorDialog(result.code ?? 'AUTH_ERROR', _errorMessage!);
    }
  }

  void _showErrorDialog(String code, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              code == 'ROLE_MISMATCH' ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
              color: code == 'ROLE_MISMATCH' ? Colors.amber[800] : Colors.red[700],
            ),
            const SizedBox(width: 8),
            Text(
              code == 'ROLE_MISMATCH' ? "Role Mismatch" : "Login Failed",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          if (code == 'ROLE_MISMATCH')
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Return to Welcome role picker
              },
              child: const Text("Switch Portal"),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your registered college email address to receive password reset instructions:",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetController,
              decoration: InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final sent = await _authService.sendPasswordResetEmail(resetController.text);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sent
                      ? "Password reset link dispatched to ${resetController.text}."
                      : "Email not found in authorized campus transport roster."),
                  backgroundColor: sent ? Colors.green[700] : Colors.red[700],
                ),
              );
            },
            child: const Text("Send Reset Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryNavy, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Icon Header Badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_roleIcon, color: _accentColor, size: 30),
                  ),
                ),
                const SizedBox(height: 20),

                // Dynamic Header Title & Subtitle
                Text(
                  _roleTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _roleSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Error Banner if present
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Please enter your email.";
                    if (!val.contains('@') || !val.contains('.')) return "Please enter a valid email address.";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Please enter your password.";
                    if (val.length < 6) return "Password must be at least 6 characters.";
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // Forgot Password Shortcut
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Action Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            "Sign In to ${widget.role.displayName}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // Demo Quick Fill Chips
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Demo Test Accounts (Quick Autofill):",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _buildDemoQuickChips(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDemoQuickChips() {
    switch (widget.role) {
      case UserRole.driver:
        return [
          _QuickChip(
            label: "Ravi (Bus 01)",
            onTap: () => setState(() => _emailController.text = 'ravi.driver@campus.edu'),
          ),
          _QuickChip(
            label: "Suresh (Bus 02)",
            onTap: () => setState(() => _emailController.text = 'suresh.driver@campus.edu'),
          ),
          _QuickChip(
            label: "Mahesh (Bus 03)",
            onTap: () => setState(() => _emailController.text = 'mahesh.driver@campus.edu'),
          ),
          _QuickChip(
            label: "Prakash (Disabled)",
            onTap: () => setState(() => _emailController.text = 'prakash.driver@campus.edu'),
          ),
          _QuickChip(
            label: "Test Student Mismatch",
            isMismatch: true,
            onTap: () => setState(() => _emailController.text = 'aditya.student@campus.edu'),
          ),
        ];
      case UserRole.student:
        return [
          _QuickChip(
            label: "Aditya (Bus 01)",
            onTap: () => setState(() => _emailController.text = 'aditya.student@campus.edu'),
          ),
          _QuickChip(
            label: "Anil (Bus 01)",
            onTap: () => setState(() => _emailController.text = 'anil.student@campus.edu'),
          ),
          _QuickChip(
            label: "Rahul (Bus 02)",
            onTap: () => setState(() => _emailController.text = 'rahul.student@campus.edu'),
          ),
          _QuickChip(
            label: "Test Driver Mismatch",
            isMismatch: true,
            onTap: () => setState(() => _emailController.text = 'ravi.driver@campus.edu'),
          ),
        ];
      case UserRole.guardian:
        return [
          _QuickChip(
            label: "Satyanarayana (Aditya & Anil)",
            onTap: () => setState(() => _emailController.text = 'satya.parent@campus.edu'),
          ),
          _QuickChip(
            label: "Rajesh (Rahul)",
            onTap: () => setState(() => _emailController.text = 'rajesh.parent@campus.edu'),
          ),
          _QuickChip(
            label: "Test Student Mismatch",
            isMismatch: true,
            onTap: () => setState(() => _emailController.text = 'aditya.student@campus.edu'),
          ),
        ];
      default:
        return [];
    }
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isMismatch;

  const _QuickChip({required this.label, required this.onTap, this.isMismatch = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isMismatch ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMismatch ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isMismatch ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
          ),
        ),
      ),
    );
  }
}

