import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/sales/domain/entities/order.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

class PdfService {
  Future<void> generateAndPrintReceipt(OrderEntity order, AppSettings settings) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.quicksandRegular();
    final fontBold = await PdfGoogleFonts.quicksandBold();
    
    // Load Logo
    final logoImage = await imageFromAssetBundle('assets/images/logo.png');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6, // A6 format (105mm x 148mm)
        margin: const pw.EdgeInsets.all(15), 
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Container(
                  height: 60,
                  width: 60,
                  child: pw.Image(logoImage),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  settings.businessName, // Dynamic Name
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Papelería Creativa', // Could be dynamic too, but keeping as tagline
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              if (settings.businessAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    settings.businessAddress,
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              if (settings.businessPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Tel: ${settings.businessPhone}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              
              // Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Orden:', style: pw.TextStyle(font: font, fontSize: 8)),
                   pw.Text(order.id.substring(0, 8).toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 8)),
                ],
              ),
              pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                     pw.Text('Fecha:', style: pw.TextStyle(font: font, fontSize: 8)),
                     pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(order.saleDate ?? DateTime.now()),
                         style: pw.TextStyle(font: font, fontSize: 8)),
                  ],
              ),
              pw.SizedBox(height: 5),
              pw.Text('Cliente:', style: pw.TextStyle(font: font, fontSize: 8)),
              pw.Text(order.customerName, style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              
              // Items
              ...order.items.map(
                (item) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          '${item.quantity}x ${item.productName}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              
              // Totals
              _buildRow('Total', order.totalPrice, fontBold, fontSize: 12),
              _buildRow('Anticipo', order.totalPrice - order.pendingBalance, font, fontSize: 10),
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
               _buildRow('SALDO PENDIENTE', order.pendingBalance, fontBold, fontSize: 12, isRed: true), // PDF doesn't support red text easily on thermal printers usually, but we can try just bold black or grayscale. Keeping it simple.
              pw.SizedBox(height: 10),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  settings.receiptFooterMessage, // Dynamic Footer
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Fecha de Entrega:',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
              ),
               pw.Center(
                child: pw.Text(
                  DateFormat('dd/MM/yyyy').format(order.deliveryDate),
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Recibo_${order.id.substring(0, 8)}',
    );
  }

  pw.Widget _buildRow(String label, double amount, pw.Font font, {double fontSize = 10, bool isRed = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: fontSize)),
        pw.Text('\$${amount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: fontSize)),
      ],
    );
  }
}
