import 'package:equatable/equatable.dart';

/// Entidad de usuario autenticado en la app
class AppUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role; // 'adminmaster' | 'cajero'
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
  });

  bool get isAdmin => role == 'adminmaster';
  bool get isCajero => role == 'cajero';

  AppUser copyWith({
    String? name,
    bool? isActive,
    DateTime? lastLogin,
  }) =>
      AppUser(
        id: id,
        email: email,
        name: name ?? this.name,
        role: role,
        isActive: isActive ?? this.isActive,
        lastLogin: lastLogin ?? this.lastLogin,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, email, role, isActive];
}
