import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String deliveryAddress;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.deliveryAddress,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? deliveryAddress,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'deliveryAddress': deliveryAddress,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: (map['id'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        fullName: (map['fullName'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        deliveryAddress: (map['deliveryAddress'] ?? '') as String,
      );

  @override
  List<Object?> get props => [id, email, fullName, phone, deliveryAddress];
}
