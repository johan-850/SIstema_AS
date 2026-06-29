// ============================================================
// lib/features/cash_register/presentation/pages/cash_register_opening_page.dart
// Apertura de caja — US-008, US-009, US-010
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

class CashRegisterOpeningPage extends ConsumerWidget {
  const CashRegisterOpeningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apertura de Caja'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(logoutUseCaseProvider).call();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Arqueo inicial — en desarrollo'),
      ),
    );
  }
}
