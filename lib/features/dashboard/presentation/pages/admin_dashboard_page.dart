// ============================================================
// lib/features/dashboard/presentation/pages/admin_dashboard_page.dart
// Dashboard principal del AdminMaster — US-048
// ============================================================

import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Text('AdminMaster Dashboard — en desarrollo'),
      ),
    );
  }
}
