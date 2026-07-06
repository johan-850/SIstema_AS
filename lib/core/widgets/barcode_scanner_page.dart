// ============================================================
// lib/core/widgets/barcode_scanner_page.dart
// Escáner de código de barras con la cámara del celular.
// Reemplaza el requerimiento original de pistola Bluetooth (EP-10)
// por decisión del negocio: se usa mobile_scanner en su lugar.
// Reutilizable desde cualquier feature (EP-03 hoy, EP-05/POS después).
// ============================================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';

/// Pantalla completa que abre la cámara y devuelve el código escaneado
/// vía `Navigator.pop(context, code)`. Devuelve `null` si el usuario
/// cancela o no concede el permiso de cámara.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;
  bool _checkingPermission = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _checkingPermission = false;
      _permissionDenied = !status.isGranted;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Escanear código de barras'),
        actions: [
          if (!_checkingPermission && !_permissionDenied)
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                final torchOn = value.torchState == TorchState.on;
                return IconButton(
                  tooltip: torchOn ? 'Apagar linterna' : 'Encender linterna',
                  icon: Icon(
                    torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  ),
                  onPressed: _controller.toggleTorch,
                );
              },
            ),
          if (!_checkingPermission && !_permissionDenied)
            IconButton(
              tooltip: 'Cambiar cámara',
              icon: const Icon(Icons.cameraswitch_rounded),
              onPressed: _controller.switchCamera,
            ),
        ],
      ),
      body: _checkingPermission
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _permissionDenied
              ? _PermissionDeniedView(onRetry: _requestPermission)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _controller, onDetect: _onDetect),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 260,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 24,
                      right: 24,
                      child: Text(
                        'Apunta la cámara al código de barras del producto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, size: 56, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            const Text(
              'Se necesita permiso de cámara para escanear códigos de barras.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Abrir ajustes de la app'),
            ),
          ],
        ),
      ),
    );
  }
}
