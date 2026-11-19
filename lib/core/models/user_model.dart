enum UserRole {
  superAdmin,
  coordinator,
  driver,
  student,
  guardian,
}

extension UserRoleExtension on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.coordinator:
        return 'coordinator';
      case UserRole.driver:
        return 'driver';
      case UserRole.student:
        return 'student';
      case UserRole.guardian:
        return 'guardian';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.coordinator:
        return 'Transport Coordinator';
      case UserRole.driver:
        return 'Bus Driver';
      case UserRole.student:
        return 'Student';
      case UserRole.guardian:
        return 'Parent / Guardian';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'admin':
        return UserRole.superAdmin;
      case 'coordinator':
        return UserRole.coordinator;
      case 'driver':
        return UserRole.driver;
      case 'student':
        return UserRole.student;
      case 'guardian':
      case 'parent':
        return UserRole.guardian;
      default:
        return UserRole.student;
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final UserRole role;
  final String? assignedBusId;
  final String? assignedRouteId;
  final String? assignedStopId;
  final List<String> linkedStudentIds; // For guardians
  final String department;
  final String rollNumber;
  final bool isApproved;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber = '',
    required this.role,
    this.assignedBusId,
    this.assignedRouteId,
    this.assignedStopId,
    this.linkedStudentIds = const [],
    this.department = 'Engineering',
    this.rollNumber = '',
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role.nameString,
      'assignedBusId': assignedBusId,
      'assignedRouteId': assignedRouteId,
      'assignedStopId': assignedStopId,
      'linkedStudentIds': linkedStudentIds,
      'department': department,
      'rollNumber': rollNumber,
      'isApproved': isApproved,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      phoneNumber: map['phoneNumber'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'student'),
      assignedBusId: map['assignedBusId'],
      assignedRouteId: map['assignedRouteId'],
      assignedStopId: map['assignedStopId'],
      linkedStudentIds: List<String>.from(map['linkedStudentIds'] ?? []),
      department: map['department'] ?? 'Engineering',
      rollNumber: map['rollNumber'] ?? '',
      isApproved: map['isApproved'] ?? true,
    );
  }
}

