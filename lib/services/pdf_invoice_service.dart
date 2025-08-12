import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

import '../models/order.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoicePdf({
    required Order order,
  }) async {
    try {
      final pdf = pw.Document();

      // Nạp font từ assets để hiển thị tiếng Việt offline
      late final pw.Font baseFont;
      late final pw.Font boldFont;
      late final pw.Font italicFont;
      late final pw.Font boldItalicFont;
      try {
        final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        baseFont = pw.Font.ttf(regularData);
      } catch (_) {
        baseFont = pw.Font.helvetica();
      }
      try {
        final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
        boldFont = pw.Font.ttf(boldData);
      } catch (_) {
        boldFont = pw.Font.helveticaBold();
      }
      try {
        final italicData = await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');
        italicFont = pw.Font.ttf(italicData);
      } catch (_) {
        italicFont = pw.Font.helveticaOblique();
      }
      try {
        final boldItalicData = await rootBundle.load('assets/fonts/NotoSans-BoldItalic.ttf');
        boldItalicFont = pw.Font.ttf(boldItalicData);
      } catch (_) {
        boldItalicFont = pw.Font.helveticaBoldOblique();
      }

      final currencySymbol = order.currencySymbol.isNotEmpty ? order.currencySymbol : '₫';
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      double subtotal = 0;
      for (final item in order.lineItems) {
        subtotal += double.tryParse(item.subtotal) ?? 0;
      }

      pw.Widget buildInfoRow(String label, String value, {PdfColor color = PdfColors.black}) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 160,
                child: pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
              ),
              pw.Expanded(
                child: pw.Text(value, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, color: color)),
              )
            ],
          ),
        );
      }

      pw.Widget headerCard() {
        return pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [
              pw.BoxShadow(color: PdfColors.grey300, blurRadius: 6, offset: const PdfPoint(0, 2)),
            ],
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Expanded(
                  child: pw.Text(
                    'Đơn hàng #${order.number.isNotEmpty ? order.number : order.id}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.Text(order.orderStatus.displayName, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ),
              ]),
              pw.SizedBox(height: 10),
              buildInfoRow('Netto', '${subtotal.toInt()}$currencySymbol'),
              if ((double.tryParse(order.totalTax) ?? 0) > 0)
                buildInfoRow('Thuế', '${(double.tryParse(order.totalTax) ?? 0).toInt()}$currencySymbol', color: PdfColors.orange),
              if ((double.tryParse(order.shippingTotal) ?? 0) > 0)
                buildInfoRow('Phí vận chuyển', '${(double.tryParse(order.shippingTotal) ?? 0).toInt()}$currencySymbol', color: PdfColors.blue),
              if ((double.tryParse(order.discountTotal) ?? 0) > 0)
                buildInfoRow('Giảm giá', '-${(double.tryParse(order.discountTotal) ?? 0).toInt()}$currencySymbol', color: PdfColors.green),
              pw.Divider(height: 16, thickness: 0.7, color: PdfColors.grey300),
              buildInfoRow('Brutto', '${(double.tryParse(order.total) ?? 0).toInt()}$currencySymbol', color: PdfColors.red),
              buildInfoRow('Số sản phẩm', '${order.lineItems.length} sản phẩm'),
              buildInfoRow('Thời gian đặt hàng', dateFormat.format(order.dateCreated.toLocal())),
              if (order.datePaid != null)
                buildInfoRow('Thời gian thanh toán', dateFormat.format(order.datePaid!.toLocal()), color: PdfColors.green),
              if (order.dateCompleted != null)
                buildInfoRow('Thời gian hoàn thành', dateFormat.format(order.dateCompleted!.toLocal()), color: PdfColors.green),
            ],
          ),
        );
      }

      pw.Widget customerCard() {
        return pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 6, offset: const PdfPoint(0, 2))],
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Thông tin khách hàng', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            buildInfoRow('Mã khách hàng', '#${order.customerId}', color: PdfColors.blue),
            if (order.billing.firstName.isNotEmpty || order.billing.lastName.isNotEmpty)
              buildInfoRow('Họ và tên', '${order.billing.firstName} ${order.billing.lastName}'.trim()),
            if (order.billing.company.isNotEmpty) buildInfoRow('Công ty', order.billing.company),
            if (order.billing.email.isNotEmpty) buildInfoRow('Email', order.billing.email),
            if (order.billing.phone.isNotEmpty) buildInfoRow('Số điện thoại', order.billing.phone),
          ]),
        );
      }

      pw.Widget paymentShippingCard() {
        final List<pw.Widget> children = [];
        if (order.paymentMethodTitle.isNotEmpty) {
          children.add(buildInfoRow('Phương thức thanh toán', order.paymentMethodTitle));
        }
        if (order.transactionId.isNotEmpty) {
          children.add(buildInfoRow('Mã giao dịch', order.transactionId, color: PdfColors.blue));
        }
        if (order.orderKey.isNotEmpty) {
          children.add(buildInfoRow('Mã đơn hàng', order.orderKey, color: PdfColors.grey600));
        }
        if (order.customerNote.isNotEmpty) {
          children.add(buildInfoRow('Ghi chú khách hàng', ''));
          children.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 4),
            child: pw.Text(order.customerNote, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
          ));
        }
        if (order.customerIpAddress.isNotEmpty) {
          children.add(buildInfoRow('IP khách hàng', order.customerIpAddress, color: PdfColors.grey600));
        }
        if (order.shipping.address1.isNotEmpty || order.shipping.city.isNotEmpty) {
          children.add(buildInfoRow('Địa chỉ giao hàng', ''));
          if (order.shipping.address1.isNotEmpty) {
            children.add(pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(order.shipping.address1, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ));
          }
          if (order.shipping.address2.isNotEmpty) {
            children.add(pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(order.shipping.address2, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ));
          }
          final cityLine = [
            if (order.shipping.city.isNotEmpty) order.shipping.city,
            if (order.shipping.state.isNotEmpty) order.shipping.state,
            if (order.shipping.postcode.isNotEmpty) order.shipping.postcode,
          ].join(', ');
          if (cityLine.trim().isNotEmpty) {
            children.add(pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(cityLine, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ));
          }
          if (order.shipping.country.isNotEmpty) {
            children.add(pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(order.shipping.country, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ));
          }
        }

        return pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            boxShadow: [pw.BoxShadow(color: PdfColors.grey300, blurRadius: 6, offset: const PdfPoint(0, 2))],
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Thông tin thanh toán & giao hàng', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...children,
          ]),
        );
      }

      pw.Widget itemsTable() {
        final headers = ['Tên sản phẩm', 'SL', 'Đơn giá', 'Thành tiền'];
        final data = order.lineItems.map((e) {
          final quantity = e.quantity;
          final unitPrice = e.price;
          final lineTotal = (double.tryParse(e.total) ?? (unitPrice * quantity)).toInt();
          return [
            e.name,
            quantity.toString(),
            '${unitPrice.toInt()}$currencySymbol',
            '$lineTotal$currencySymbol',
          ];
        }).toList();

        return pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          cellStyle: pw.TextStyle(fontSize: 10, font: baseFont),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        );
      }

      pw.Widget totalsSection() {
        final totalTax = (double.tryParse(order.totalTax) ?? 0).toInt();
        final shipping = (double.tryParse(order.shippingTotal) ?? 0).toInt();
        final discount = (double.tryParse(order.discountTotal) ?? 0).toInt();
        final grandTotal = (double.tryParse(order.total) ?? 0).toInt();

        pw.Widget row(String label, String value, {PdfColor color = PdfColors.black, bool bold = false}) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 11))),
              pw.Text(value, style: pw.TextStyle(color: color, fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ]),
          );
        }

        return pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(children: [
            row('Tổng cộng', '${subtotal.toInt()}$currencySymbol'),
            if (totalTax > 0) row('Thuế', '$totalTax$currencySymbol', color: PdfColors.orange),
            if (shipping > 0) row('Phí vận chuyển', '$shipping$currencySymbol', color: PdfColors.blue),
            if (discount > 0) row('Giảm giá', '-$discount$currencySymbol', color: PdfColors.green),
            pw.Divider(height: 16, thickness: 0.7, color: PdfColors.grey300),
            row('Tổng thanh toán', '$grandTotal$currencySymbol', color: PdfColors.red, bold: true),
          ]),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.all(20),
            theme: pw.ThemeData.withFont(
              base: baseFont,
              bold: boldFont,
              italic: italicFont,
              boldItalic: boldItalicFont,
            ),
          ),
          build: (context) => [
            headerCard(),
            pw.SizedBox(height: 12),
            customerCard(),
            pw.SizedBox(height: 12),
            paymentShippingCard(),
            pw.SizedBox(height: 16),
            pw.Text('Danh sách sản phẩm', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            itemsTable(),
            pw.SizedBox(height: 12),
            totalsSection(),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text('Trang ${context.pageNumber}/${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
        ),
      );

      return pdf.save();
    } catch (e) {
      // Ném lỗi để UI xử lý
      rethrow;
    }
  }
}


