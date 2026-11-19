import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/models/user_model.dart';
import 'core/services/auth_service.dart';
import 'core/services/simulation_service.dart';
import 'features/auth/splash_screen.dart';
import 'features/student/student_dashboard_screen.dart';
import 'features/parent/parent_dashboard_screen.dart';
import 'features/driver/driver_dashboard_screen.dart';
import 'features/admin/admin_control_room_screen.dart';
import 'features/research/research_dashboard_screen.dart';
import 'shared/role_switcher_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start realistic GPS tracking simulation engine for multi-bus demo
  SimulationService().startSimulation();
  runApp(const SmartCampusTransportApp());
}

class SmartCampusTransportApp extends StatelessWidget {
  const SmartCampusTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class RoleGatewayScreen extends StatefulWidget {
  const RoleGatewayScreen({super.key});

  @override
  State<RoleGatewayScreen> createState() => _RoleGatewayScreenState();
}

class _RoleGatewayScreenState extends State<RoleGatewayScreen> {
  final authService = AuthService();
  late UserModel _currentUser;
  bool _showResearchModule = false;

  @override
  void initState() {
    super.initState();
    _currentUser = authService.currentUser ?? authService.demoAccounts.first;
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _currentUser = authService.currentUser!;
      _showResearchModule = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Role Switcher Navigation Bar across the top of the interface
          RoleSwitcherBar(
            currentRole: _currentUser.role,
            onRoleSelected: _onRoleChanged,
          ),

          // Active Role Experience
          Expanded(
            child: _showResearchModule
                ? ResearchDashboardScreen(
                    onBackToControlRoom: () => setState(() => _showResearchModule = false),
                  )
                : _buildActiveRoleScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoleScreen() {
    switch (_currentUser.role) {
      case UserRole.superAdmin:
      case UserRole.coordinator:
        return AdminControlRoomScreen(
          admin: _currentUser,
          onOpenResearch: () => setState(() => _showResearchModule = true),
        );
      case UserRole.driver:
        return DriverDashboardScreen(driver: _currentUser);
      case UserRole.student:
        return StudentDashboardScreen(student: _currentUser);
      case UserRole.guardian:
        return ParentDashboardScreen(guardian: _currentUser);
    }
  }
}

