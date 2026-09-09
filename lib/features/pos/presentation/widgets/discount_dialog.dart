// ============================================================
// lib/features/pos/presentation/widgets/discount_dialog.dart
// US-029: captura de descuento, por ítem o global.
//
// El cajero puede escribir un porcentaje o un monto, pero lo que sale
// de acá siempre son pesos: el monto resuelto es lo que se persiste,
// para que el recibo impreso y el cuadre de caja no puedan diferir por
// redondeo.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

enum _DiscountMode { percent, amount }

class DiscountDialog extends StatefulWidget {
  /// Sobre cuánto se calcula el descuento (subtotal del ítem, o lo que
  /// queda de la venta tras los descuentos por ítem).
  final double baseAmount;

  /// Descuento ya aplicado, para poder editarlo o quitarlo.
  final double currentDiscount;

  final String title;

  const DiscountDialog({
    super.key,
    required this.baseAmount,
    required this.currentDiscount,
    required this.title,
  });

  /// Devuelve el descuento en pesos, o null si se canceló.
  static Future<double?> show(
    BuildContext context, {
    required double baseAmount,
    required double currentDiscount,
    required String title,
  }) =>
      showDialog<double>(
        context: context,
        builder: (_) => DiscountDialog(
          baseAmount: baseAmount,
          currentDiscount: currentDiscount,
          title: title,
        ),
      );

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final _controller = TextEditingController();
  _DiscountMode _mode = _DiscountMode.percent;
  String? _error;

  final _currencyFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (widget.currentDiscount > 0) {
      // Se precarga como monto: es el valor exacto que se guardó, sin
      // reconstruir un porcentaje que podría no ser redondo.
      _mode = _DiscountMode.amount;
      _controller.text = widget.currentDiscount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Monto en pesos que representa lo escrito, según el modo activo.
  double? get _resolvedAmount {
    final raw = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (raw == null) return null;
    if (raw < 0) return null;

    if (_mode == _DiscountMode.percent) {
      if (raw > 100) return null;
      return widget.baseAmount * (raw / 100);
    }
    return raw;
  }

  void _submit() {
    final amount = _resolvedAmount;

    if (amount == null) {
      setState(() {
        _error = _mode == _DiscountMode.percent
            ? 'Ingresa un porcentaje entre 0 y 100.'
            : 'Ingresa un monto válido.';
      });
      return;
    }

    if (amount > widget.baseAmount) {
      setState(() => _error =
          'El descuento no puede superar ${_currencyFmt.format(widget.baseAmount)}.');
      return;
    }

    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _resolvedAmount;

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: Text(widget.title, style: const TextStyle(fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre ${_currencyFmt.format(widget.baseAmount)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SegmentedButton<_DiscountMode>(
            segments: const [
              ButtonSegment(value: _DiscountMode.percent, label: Text('Porcentaje')),
              ButtonSegment(value: _DiscountMode.amount, label: Text('Monto')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: _mode == _DiscountMode.percent ? 'Porcentaje' : 'Monto',
              prefixIcon: Icon(
                _mode == _DiscountMode.percent ? Icons.percent_rounded : Icons.attach_money_rounded,
              ),
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
          if (preview != null && preview > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Se descontarán ${_currencyFmt.format(preview)}',
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.currentDiscount > 0)
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: const Text('Quitar', style: TextStyle(color: AppColors.error)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Aplicar')),
      ],
    );
  }
}
