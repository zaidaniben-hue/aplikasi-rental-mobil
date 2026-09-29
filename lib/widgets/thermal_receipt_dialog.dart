import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ThermalReceiptDialog extends StatefulWidget {
  final Rental rental;
  final Inspection? checkoutInspection;
  final Inspection? checkinInspection;

  const ThermalReceiptDialog({
    super.key,
    required this.rental,
    this.checkoutInspection,
    this.checkinInspection,
  });

  @override
  State<ThermalReceiptDialog> createState() => _ThermalReceiptDialogState();
}

class _ThermalReceiptDialogState extends State<ThermalReceiptDialog> {
  bool _is80mm = true; // 80mm or 58mm thermal paper size

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cetak Bukti Transaksi: ${widget.rental.transactionCode}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Format Selector Bar
            Row(
              children: [
                const Text('Format Kertas Termal Kasir: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('80mm (Standard POS)'),
                  selected: _is80mm,
                  onSelected: (val) => setState(() => _is80mm = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('58mm (Mini POS)'),
                  selected: !_is80mm,
                  onSelected: (val) => setState(() => _is80mm = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // PDF Preview Area
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PdfPreview(
                  build: (format) => _generatePdfReceipt(_is80mm),
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  initialPageFormat: _is80mm ? PdfPageFormat.roll80 : PdfPageFormat.roll57,
                  actions: [
                    PdfPreviewAction(
                      icon: const Icon(Icons.print),
                      onPressed: (context, build, pageFormat) async {
                        final doc = await _generatePdfReceipt(_is80mm);
                        await Printing.layoutPdf(onLayout: (_) => doc);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdfReceipt(bool is80) async {
    final pdf = pw.Document();
    final pageFormat = is80 ? PdfPageFormat.roll80 : PdfPageFormat.roll57;

    final rental = widget.rental;
    final vehicle = rental.vehicle;
    final customer = rental.customer;
    final netPay = (rental.totalAmount - rental.downPayment - rental.depositAmount);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('RENTDESK INDONESIA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('Sistem Manajemen Rental Armada', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Telp: 0812-3456-7890 | Cabang Utama', style: const pw.TextStyle(fontSize: 8)),
                    pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // Transaction Info
              _pwRow('No. Transaksi', rental.transactionCode, isBold: true),
              _pwRow('Tgl Cetak', dateFormat.format(DateTime.now())),
              _pwRow('Status Sewa', rental.rentalStatus),
              _pwRow('Metode Bayar', rental.paymentMethod),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Customer Info
              pw.Text('INFORMASI PENYEWA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              _pwRow('Nama', customer?.fullName ?? 'Pelanggan'),
              _pwRow('NIK / SIM', '${customer?.nik ?? '-'} / ${customer?.simNumber ?? '-'}'),
              _pwRow('No. HP/WA', customer?.phoneNumber ?? '-'),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Vehicle Info
              pw.Text('UNIT ARMADA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              _pwRow('Plat / Model', '${vehicle?.plateNumber ?? '-'} - ${vehicle?.brand ?? ''} ${vehicle?.model ?? ''}'),
              _pwRow('Mulai Sewa', dateFormat.format(rental.startTime)),
              _pwRow('Rencana Kembali', dateFormat.format(rental.plannedEndTime)),
              if (rental.actualEndTime != null)
                _pwRow('Aktual Kembali', dateFormat.format(rental.actualEndTime!)),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Cost Breakdown
              pw.Text('RINCIAN PEMBAYARAN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              _pwRow('Tarif Harian', currencyFormat.format(rental.dailyRate)),
              _pwRow('Durasi Sewa', '${rental.durationDays} Hari'),
              _pwRow('Biaya Pokok', currencyFormat.format(rental.baseAmount)),

              if (rental.overtimeFee > 0)
                _pwRow('Denda Overtime (${rental.overtimeHours.toStringAsFixed(1)} Jam)', currencyFormat.format(rental.overtimeFee)),

              if (rental.fuelFee > 0)
                _pwRow('Biaya Selisih BBM', currencyFormat.format(rental.fuelFee)),

              if (rental.damageFee > 0)
                _pwRow('Biaya Perbaikan Cacat/Lecet', currencyFormat.format(rental.damageFee)),

              pw.Divider(thickness: 1),
              _pwRow('TOTAL TAGIHAN', currencyFormat.format(rental.totalAmount), isBold: true, fontSize: 11),
              pw.SizedBox(height: 2),

              _pwRow('Uang Muka (DP)', '- ${currencyFormat.format(rental.downPayment)}'),
              _pwRow('Deposit Jaminan', '- ${currencyFormat.format(rental.depositAmount)}'),

              if (rental.refundDeposit > 0)
                _pwRow('PENGEMBALIAN DEPOSIT', currencyFormat.format(rental.refundDeposit), isBold: true),

              if (netPay > 0)
                _pwRow('SISA HARUS DIBAYAR', currencyFormat.format(netPay), isBold: true, fontSize: 10),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Footer Note
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Terima kasih atas kepercayaan Anda!', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Harap simpan struk ini sebagai bukti serah terima resmi.', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Unit harus dikembalikan tepat waktu & BBM sesuai.', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pwRow(String label, String value, {bool isBold = false, double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
