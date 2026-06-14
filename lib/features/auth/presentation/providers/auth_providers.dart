// ============================================================
// lib/features/auth/presentation/providers/auth_providers.dart
// Providers de autenticación con Supabase Auth + Riverpod
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Cliente Supabase ────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ── Stream de cambios de sesión ─────────────────────────────
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

// ── Estado actual de autenticación ─────────────────────────
final authStateProvider = StreamProvider<Session?>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange.map(
    (event) => event.session,
  );
});

// ── Rol del usuario actual ─────────────────────────────────
final currentUserRoleProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final metadata = client.auth.currentUser?.userMetadata;
  return metadata?['role'] as String?;
});

// ── Usuario actual ─────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
