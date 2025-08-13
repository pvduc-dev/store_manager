import 'dart:typed_data';

import 'package:flutter/services.dart';
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
                'HÓA ĐƠN MUA HÀNG',
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
                      pw.Text('Số đơn hàng: #${order.id}', style: pw.TextStyle(font: ttf)),
                      pw.SizedBox(height: 5),
                      pw.Text('Ngày tạo: ${_formatDate(order.dateCreated)}', style: pw.TextStyle(font: ttf)),
                      pw.SizedBox(height: 5),
                      pw.Text('Trạng thái: ${order.orderStatus.displayName}', style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Customer Info
              pw.Text(
                'THÔNG TIN KHÁCH HÀNG',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Tên: ${order.customerName}', style: pw.TextStyle(font: ttf)),
              if (order.billing.phone.isNotEmpty)
                pw.Text('Điện thoại: ${order.billing.phone}', style: pw.TextStyle(font: ttf)),
              if (order.billing.email.isNotEmpty)
                pw.Text('Email: ${order.billing.email}', style: pw.TextStyle(font: ttf)),
              if (order.billing.address1.isNotEmpty)
                pw.Text('Địa chỉ: ${order.billing.address1}, ${order.billing.city}', style: pw.TextStyle(font: ttf)),
              pw.SizedBox(height: 20),
              
              // Products Table
              pw.Text(
                'CHI TIẾT SẢN PHẨM',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Sản phẩm', 'SKU', 'Số lượng', 'Đơn giá', 'Thành tiền'],
                data: order.lineItems.map((item) => [
                  item.name,
                  item.sku,
                  item.quantity.toString(),
                  CurrencyFormatter.formatWithSymbol(item.price, order.currencySymbol),
                  CurrencyFormatter.formatWithSymbol(item.price * item.quantity, order.currencySymbol),
                ]).toList(),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
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
                      pw.Text('Tổng cộng: ${CurrencyFormatter.formatWithSymbol(double.parse(order.total), order.currencySymbol)}',
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
        }
      ),
    );

    return pdf.save();
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
