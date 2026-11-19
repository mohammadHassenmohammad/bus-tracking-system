import 'dart:async';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? code;
  final String? error;

  const AuthResult({
    required this.success,
    this.user,
    this.code,
    this.error,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Complete Verified Accounts Catalog across Drivers, Students, Guardians, and Admins
  static final List<UserModel> _userDirectory = [
    // 1. DRIVERS (Independent credentials & assigned buses)
    const UserModel(
      uid: 'drv_ravi',
      email: 'ravi.driver@campus.edu',
      displayName: 'Ravi Kumar',
      phoneNumber: '+91 98765 11001',
      role: UserRole.driver,
      assignedBusId: 'bus_01',
      assignedRouteId: 'route_01',
      department: 'Fleet Operations',
      isApproved: true,
    ),
    const UserModel(
      uid: 'drv_suresh',
      email: 'suresh.driver@campus.edu',
      displayName: 'Suresh Varma',
      phoneNumber: '+91 98765 11002',
      role: UserRole.driver,
      assignedBusId: 'bus_02',
      assignedRouteId: 'route_02',
      department: 'Fleet Operations',
      isApproved: true,
    ),
    const UserModel(
      uid: 'drv_mahesh',
      email: 'mahesh.driver@campus.edu',
      displayName: 'Mahesh Babu',
      phoneNumber: '+91 98765 11003',
      role: UserRole.driver,
      assignedBusId: 'bus_03',
      assignedRouteId: 'route_03',
      department: 'Fleet Operations',
      isApproved: true,
    ),
    const UserModel(
      uid: 'drv_prakash',
      email: 'prakash.driver@campus.edu',
      displayName: 'Prakash Rao',
      phoneNumber: '+91 98765 11004',
      role: UserRole.driver,
      assignedBusId: 'bus_04',
      assignedRouteId: 'route_04',
      department: 'Fleet Operations',
      isApproved: false, // Disabled account demo
    ),

    // 2. STUDENTS (Assigned buses, routes, and designated pickup stops)
    const UserModel(
      uid: 'std_aditya',
      email: 'aditya.student@campus.edu',
      displayName: 'Aditya Varma',
      phoneNumber: '+91 98480 11223',
      role: UserRole.student,
      assignedBusId: 'bus_01',
      assignedRouteId: 'route_01',
      assignedStopId: 'stop_01_03',
      rollNumber: '21A91A0501',
      department: 'Computer Science & Engineering',
      isApproved: true,
    ),
    const UserModel(
      uid: 'std_anil',
      email: 'anil.student@campus.edu',
      displayName: 'Anil Varma',
      phoneNumber: '+91 98480 11224',
      role: UserRole.student,
      assignedBusId: 'bus_01',
      assignedRouteId: 'route_01',
      assignedStopId: 'stop_01_02',
      rollNumber: '21A91A0502',
      department: 'Information Technology',
      isApproved: true,
    ),
    const UserModel(
      uid: 'std_rahul',
      email: 'rahul.student@campus.edu',
      displayName: 'Rahul Sharma',
      phoneNumber: '+91 98480 11225',
      role: UserRole.student,
      assignedBusId: 'bus_02',
      assignedRouteId: 'route_02',
      assignedStopId: 'stop_02_02',
      rollNumber: '21A91A0503',
      department: 'Electronics & Communication',
      isApproved: true,
    ),

    // 3. PARENTS / GUARDIANS (Linked student wards)
    const UserModel(
      uid: 'parent_satya',
      email: 'satya.parent@campus.edu',
      displayName: 'Satyanarayana Varma',
      phoneNumber: '+91 98765 33001',
      role: UserRole.guardian,
      linkedStudentIds: ['std_aditya', 'std_anil'],
      department: 'Guardian Portal',
      isApproved: true,
    ),
    const UserModel(
      uid: 'parent_rajesh',
      email: 'rajesh.parent@campus.edu',
      displayName: 'Rajesh Sharma',
      phoneNumber: '+91 98765 33002',
      role: UserRole.guardian,
      linkedStudentIds: ['std_rahul'],
      department: 'Guardian Portal',
      isApproved: true,
    ),

    // 4. ADMINISTRATOR & COORDINATOR
    const UserModel(
      uid: 'admin_001',
      email: 'admin@campus.edu',
      displayName: 'Dr. R. Ramanujan',
      phoneNumber: '+91 98765 43210',
      role: UserRole.superAdmin,
      department: 'Campus Administration',
      isApproved: true,
    ),
    const UserModel(
      uid: 'coord_001',
      email: 'controlroom@campus.edu',
      displayName: 'Prof. K. Venkatesh',
      phoneNumber: '+91 98765 43211',
      role: UserRole.coordinator,
      department: 'Central Transport Office',
      isApproved: true,
    ),
  ];

  List<UserModel> get demoAccounts => _userDirectory;

  /// Secure Role-Enforced Login
  /// Authenticates credentials AND strictly checks that the user has the expected role.
  /// Prevents students from logging in as drivers, or parents accessing student accounts.
  Future<AuthResult> loginWithRole({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final cleanEmail = email.trim().toLowerCase();

    // 1. Check account existence
    final user = _userDirectory.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
      orElse: () => const UserModel(uid: '', email: '', displayName: '', role: UserRole.student),
    );

    if (user.uid.isEmpty) {
      return const AuthResult(
        success: false,
        code: 'USER_NOT_FOUND',
        error: 'No registered transportation account found with this email address.',
      );
    }

    // 2. Validate password (Default testing password: 'password123' or 'admin123')
    if (password != 'password123' && password != 'admin123') {
      return const AuthResult(
        success: false,
        code: 'WRONG_PASSWORD',
        error: 'Invalid password. Please check your credentials and try again.',
      );
    }

    // 3. Check if account is approved / enabled
    if (!user.isApproved) {
      return const AuthResult(
        success: false,
        code: 'ACCOUNT_DISABLED',
        error: 'Your account has been deactivated by the transportation administrator. Please contact the campus transport office.',
      );
    }

    // 4. STRICT ROLE VERIFICATION & MISMATCH DETECTION
    bool isRoleMatch = false;
    if (expectedRole == UserRole.driver && user.role == UserRole.driver) {
      isRoleMatch = true;
    } else if (expectedRole == UserRole.student && user.role == UserRole.student) {
      isRoleMatch = true;
    } else if (expectedRole == UserRole.guardian && user.role == UserRole.guardian) {
      isRoleMatch = true;
    } else if ((expectedRole == UserRole.superAdmin || expectedRole == UserRole.coordinator) &&
        (user.role == UserRole.superAdmin || user.role == UserRole.coordinator)) {
      isRoleMatch = true;
    }

    if (!isRoleMatch) {
      return AuthResult(
        success: false,
        code: 'ROLE_MISMATCH',
        error: 'Role Mismatch: This account belongs to a ${user.role.displayName}. Please select the ${user.role.displayName} Login portal.',
      );
    }

    // Authentication & authorization successful
    _currentUser = user;
    _authStateController.add(_currentUser);
    return AuthResult(success: true, user: user);
  }

  /// Forgot Password Request Workflow
  Future<bool> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();
    return _userDirectory.any((u) => u.email.toLowerCase() == cleanEmail);
  }

  /// Sign out & destroy active user session
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _authStateController.add(null);
  }

  void switchDemoRole(UserRole role) {
    _currentUser = _userDirectory.firstWhere(
      (u) => u.role == role,
      orElse: () => _userDirectory.first,
    );
    _authStateController.add(_currentUser);
  }
}
