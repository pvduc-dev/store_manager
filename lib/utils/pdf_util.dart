import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:store_manager/models/order.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class PdfUtil {

  static Future<Uint8List> generateOrderPdf(Order order) async {
    final pdf = pw.Document();

    // Load font hỗ trợ tiếng Việt
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);



    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'FAKTURA ZAKUPU',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Numer faktury: ${order.id}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Data wystawienia: ${_formatDate(order.dateCreated)}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 5),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Customer Info
              pw.Text(
                'Dane klienta',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Nazwa: ${order.customerName}',
                style: pw.TextStyle(font: ttf),
              ),
              if (order.billing.phone.isNotEmpty)
                pw.Text(
                  'Telefon: ${order.billing.phone}',
                  style: pw.TextStyle(font: ttf),
                ),
              if (order.billing.email.isNotEmpty)
                pw.Text(
                  'Email: ${order.billing.email}',
                  style: pw.TextStyle(font: ttf),
                ),
              if (order.billing.company.isNotEmpty)
                pw.Text(
                  'NIP: ${order.billing.company}',
                  style: pw.TextStyle(font: ttf),
                ),
              if (order.billing.address1.isNotEmpty)
                pw.Text(
                  'Adres: ${order.billing.address1}, ${order.billing.city}',
                  style: pw.TextStyle(font: ttf),
                ),
              pw.SizedBox(height: 20),

              // Products Table
              pw.Text(
                'Szczegóły produktów',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['ID', 'Nazwa produktu', 'Ilość', 'Cena', 'Suma'],
                data: order.lineItems
                    .map(
                      (item) => [
                        item.name,
                        item.quantity.toString(),
                        CurrencyFormatter.formatPLN(item.price),
                        CurrencyFormatter.formatPLN(
                          item.price * item.quantity,
                        ),
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                  font: ttf,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(font: ttf),
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Netto: ${CurrencyFormatter.formatPLNFromString(order.total)}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        'Brutto: ${CurrencyFormatter.formatPLNFromString(order.total)}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
