// ============================================================
// lib/features/pos/presentation/pages/pos_page.dart
// Punto de Venta — US-025 al US-033
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        actions: [
          // US-018: único punto de entrada del Cajero al catálogo por ahora
          IconButton(
            tooltip: 'Ver catálogo',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push('/catalog'),
          ),
        ],
      ),
      body: const Center(
        child: Text('POS — en desarrollo'),
      ),
    );
  }
}
