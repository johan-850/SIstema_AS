// ============================================================
// lib/features/pos/presentation/widgets/discount_pin_dialog.dart
// US-029: pide el PIN del AdminMaster cuando el descuento supera el
// umbral configurado.
//
// Este diálogo NO valida nada: solo captura. Quien decide si el PIN
// sirve es confirm_sale del lado del servidor, en la misma transacción
// que crea la venta. Si la validación viviera acá, un cajero podría
// saltársela llamando al RPC directamente.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class DiscountPinDialog extends StatefulWidget {
  final double discountPercent;

  const DiscountPinDialog({super.key, required this.discountPercent});

  /// Devuelve el PIN escrito, o null si se canceló.
  static Future<String?> show(BuildContext context, {required double discountPercent}) =>
      showDialog<String>(
        context: context,
        builder: (_) => DiscountPinDialog(discountPercent: discountPercent),
      );

  @override
  State<DiscountPinDialog> createState() => _DiscountPinDialogState();
}

class _DiscountPinDialogState extends State<DiscountPinDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.isEmpty) return;
    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Text('Autorización requerida', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Este descuento es del ${widget.discountPercent.toStringAsFixed(1)}% y supera el máximo '
            'permitido sin autorización. Pide al AdminMaster que ingrese su PIN.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 4),
            decoration: InputDecoration(
              labelText: 'PIN de autorización',
              prefixIcon: const Icon(Icons.pin_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Autorizar')),
      ],
    );
  }
}
