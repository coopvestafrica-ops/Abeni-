import 'package:equatable/equatable.dart';

/// Roles that an [AppUser] can hold.
///
/// - [customer]  — default for any account that signs up through the
///   customer-facing app.
/// - [staff]     — can view and manage orders / inventory in the admin app
///   but cannot manage other admin users.
/// - [admin]     — full admin access. Can promote staff and other admins.
enum UserRole { customer, staff, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get wireKey {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.staff:
        return 'staff';
      case UserRole.admin:
        return 'admin';
    }
  }

  bool get isAdminOrStaff =>
      this == UserRole.admin || this == UserRole.staff;

  static UserRole fromString(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}

class AppUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String deliveryAddress;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.deliveryAddress,
    this.role = UserRole.customer,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isAdminOrStaff => role.isAdminOrStaff;

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? deliveryAddress,
    UserRole? role,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        role: role ?? this.role,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'deliveryAddress': deliveryAddress,
        'role': role.wireKey,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: (map['id'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        fullName: (map['fullName'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        deliveryAddress: (map['deliveryAddress'] ?? '') as String,
        role: UserRoleX.fromString(map['role'] as String?),
      );

  @override
  List<Object?> get props =>
      [id, email, fullName, phone, deliveryAddress, role];
}
