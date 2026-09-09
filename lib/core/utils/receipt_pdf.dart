// ============================================================
// lib/core/utils/receipt_pdf.dart
// Genera el PDF del recibo — extraído de ReceiptPage (EP-05) para
// reutilizarlo también desde el detalle de venta del AdminMaster
// (EP-08, "recibo regenerable"). Sin dependencias de features/ a
// propósito: recibe primitivos, no entidades de dominio.
// ============================================================

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// [subtotal] es el bruto (cantidad × precio); [discount] es lo que se
/// rebajó de ese ítem. El recibo muestra ambos para que el cliente vea
/// el precio original y el ahorro (US-029).
typedef ReceiptLineItem = ({String name, int quantity, double subtotal, double discount});

String paymentMethodLabel(String method) => switch (method) {
      'efectivo' => 'Efectivo',
      'transferencia' => 'Transferencia',
      'mixto' => 'Mixto (efectivo + transferencia)',
      _ => method,
    };

Future<Uint8List> buildReceiptPdfBytes({
  required String saleId,
  required DateTime createdAt,
  required double total,
  required String paymentMethod,
  required List<ReceiptLineItem> items,
  double? cashAmount,
  double? transferAmount,
  double? changeAmount,
  double globalDiscount = 0,
}) async {
  final currencyFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  final dateFmt = DateFormat('dd/MM/yyyy hh:mm a', 'es');
  final isCash = paymentMethod == 'efectivo';
  final isMixed = paymentMethod == 'mixto';

  // US-029: el bruto se recalcula sumando los ítems, no se recibe, para
  // que el recibo no pueda contradecir sus propias líneas.
  final gross = items.fold(0.0, (sum, i) => sum + i.subtotal);
  final itemDiscounts = items.fold(0.0, (sum, i) => sum + i.discount);
  final totalDiscount = itemDiscounts + globalDiscount;
  final hasDiscount = totalDiscount > 0;

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text('Abarrotería Pro', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text(dateFmt.format(createdAt.toLocal()), style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          ...items.map((i) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('${i.name} x${i.quantity}', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Text(currencyFmt.format(i.subtotal), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    if (i.discount > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('  Descuento', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('-${currencyFmt.format(i.discount)}', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                  ],
                ),
              )),
          pw.Divider(),
          // US-029: subtotal y descuento solo aparecen si hubo rebaja —
          // en una venta sin descuento el recibo queda igual que antes.
          if (hasDiscount) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(currencyFmt.format(gross), style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Descuento', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('-${currencyFmt.format(totalDiscount)}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 2),
          ],
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(currencyFmt.format(total), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text('Método: ${paymentMethodLabel(paymentMethod)}', style: const pw.TextStyle(fontSize: 8)),
          if (isCash) ...[
            pw.Text('Recibido: ${currencyFmt.format(cashAmount ?? 0)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Cambio: ${currencyFmt.format(changeAmount ?? 0)}', style: const pw.TextStyle(fontSize: 8)),
          ],
          if (isMixed) ...[
            pw.Text('Efectivo: ${currencyFmt.format(cashAmount ?? 0)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Transferencia: ${currencyFmt.format(transferAmount ?? 0)}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ],
      ),
    ),
  );
  return doc.save();
}
