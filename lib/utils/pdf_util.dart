import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:store_manager/models/order.dart';
import 'package:store_manager/utils/currency_formatter.dart';
import 'package:http/http.dart' as http;

class PdfUtil {
  // Helper function để tải và chuyển đổi hình ảnh từ URL
  static Future<pw.ImageProvider?> _loadImageFromUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Lỗi tải hình ảnh: $e');
    }
    return null;
  }

  // Helper function để tải tất cả hình ảnh sản phẩm
  static Future<Map<int, pw.ImageProvider?>> _loadProductImages(
    List<OrderItem> lineItems,
  ) async {
    Map<int, pw.ImageProvider?> imageMap = {};
    
    for (OrderItem item in lineItems) {
      if (item.image?.src != null && item.image!.src.isNotEmpty) {
        imageMap[item.id] = await _loadImageFromUrl(item.image!.src);
      } else {
        imageMap[item.id] = null;
      }
    }
    
    return imageMap;
  }

  // Helper function để lấy thông tin kho hàng từ warehouse field
  static String _getWarehouseInfo(OrderItem item) {
    return item.warehouse;
  }

  // Helper function để tính toán giá netto và brutto
  static Map<String, double> _calculateNettoAndBrutto(Order order) {
    // Simplified calculation - no shipping or fee lines in new model
    double lineItemsSubtotal = 0.0;
    for (final lineItem in order.lineItems) {
      lineItemsSubtotal += lineItem.total; // Use total getter
    }
    
    // Simplified calculation for new model
    final netto = lineItemsSubtotal;
    final totalTax = order.taxFeeAmount;
    final brutto = order.total;
    
    return {
      'netto': netto,
      'brutto': brutto,
      'totalTax': totalTax,
      'shippingTotal': 0.0,
      'shippingTax': 0.0,
    };
  }

  // Helper function để tạo column widths theo điều kiện
  static Map<int, pw.TableColumnWidth> _getColumnWidths(bool isShowWarehouse) {
    if (isShowWarehouse) {
      return {
        0: const pw.FixedColumnWidth(50), // Hình ảnh
        1: const pw.FlexColumnWidth(3),   // Tên sản phẩm
        2: const pw.FixedColumnWidth(70), // Magazyn
        3: const pw.FixedColumnWidth(50), // Số lượng
        4: const pw.FixedColumnWidth(70), // Giá
        5: const pw.FixedColumnWidth(70), // Tổng
      };
    } else {
      return {
        0: const pw.FixedColumnWidth(60), // Hình ảnh
        1: const pw.FlexColumnWidth(3),   // Tên sản phẩm
        2: const pw.FixedColumnWidth(60), // Số lượng
        3: const pw.FixedColumnWidth(80), // Giá
        4: const pw.FixedColumnWidth(80), // Tổng
      };
    }
  }

  // Helper function để tạo header row theo điều kiện
  static pw.TableRow _buildHeaderRow(pw.Font ttf, bool isShowWarehouse) {
    List<pw.Widget> headerCells = [
      // Hình ảnh
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Zdjęcie produktu',
          style: pw.TextStyle(
            font: ttf,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Tên sản phẩm
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Nazwa produktu',
          style: pw.TextStyle(
            font: ttf,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    ];

    // Thêm cột Magazyn nếu cần
    if (isShowWarehouse) {
      headerCells.add(
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            'Magazyn',
            style: pw.TextStyle(
              font: ttf,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Thêm các cột còn lại
    headerCells.addAll([
      // Số lượng
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Ilość',
          style: pw.TextStyle(
            font: ttf,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Giá
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Cena',
          style: pw.TextStyle(
            font: ttf,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
      // Tổng
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          'Suma',
          style: pw.TextStyle(
            font: ttf,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ]);

    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      children: headerCells,
    );
  }

  // Helper function để tạo các row của bảng sản phẩm với hình ảnh (cho MultiPage)
  static List<pw.Widget> _buildProductTableRowsForMultiPage(
    List<OrderItem> lineItems, 
    pw.Font ttf,
    Map<int, pw.ImageProvider?> productImages,
    bool isShowWarehouse,
  ) {
    List<pw.Widget> widgets = [];
    
    for (OrderItem item in lineItems) {
      final imageProvider = productImages[item.id];

      // Tạo danh sách các cell cho row
      List<pw.Widget> rowCells = [
        // Cột hình ảnh
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Container(
            height: 50,
            width: 50,
            child: imageProvider != null
                ? pw.Image(imageProvider, fit: pw.BoxFit.cover)
                : pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'No Image',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
          ),
        ),
        // Cột tên sản phẩm
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            item.name,
            style: pw.TextStyle(font: ttf),
          ),
        ),
      ];

      // Thêm cột kho hàng nếu cần
      if (isShowWarehouse) {
        rowCells.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              _getWarehouseInfo(item),
              style: pw.TextStyle(font: ttf),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );
      }

      // Thêm các cột còn lại
      rowCells.addAll([
        // Cột số lượng
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            item.quantity.toString(),
            style: pw.TextStyle(font: ttf),
            textAlign: pw.TextAlign.center,
          ),
        ),
        // Cột giá
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            CurrencyFormatter.formatPLN(item.price),
            style: pw.TextStyle(font: ttf),
            textAlign: pw.TextAlign.center,
          ),
        ),
        // Cột tổng
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            CurrencyFormatter.formatPLN(item.price * item.quantity),
            style: pw.TextStyle(font: ttf),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ]);

      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: _getColumnWidths(isShowWarehouse),
          children: [
            pw.TableRow(children: rowCells),
          ],
        ),
      );
    }
    
    return widgets;
  }



  static Future<Uint8List> generateOrderPdf(Order order, bool isShowWarehouse) async {
    final pdf = pw.Document();

    // Load font hỗ trợ tiếng Việt
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Tải tất cả hình ảnh sản phẩm trước
    final productImages = await _loadProductImages(order.lineItems);
    
    // Tính toán giá netto và brutto
    final priceCalculations = _calculateNettoAndBrutto(order);



    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
              padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey),
                ),
              ),
              child: pw.Text(
                'FAKTURA ZAKUPU - Strona ${context.pageNumber}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            );
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Strona ${context.pageNumber} z ${context.pagesCount}',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
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
              if (order.billing.nip.isNotEmpty)
                pw.Text(
                  'NIP: ${order.billing.nip}',
                  style: pw.TextStyle(font: ttf),
                ),
              if (order.billing.address.isNotEmpty)
                pw.Text(
                  'Adres: ${order.billing.address}',
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
              
              // Header bảng sản phẩm
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: _getColumnWidths(isShowWarehouse),
                children: [
                  _buildHeaderRow(ttf, isShowWarehouse),
                ],
              ),
              
              // Các rows sản phẩm - sẽ được chia trang tự động
              ..._buildProductTableRowsForMultiPage(order.lineItems, ttf, productImages, isShowWarehouse),
              pw.SizedBox(height: 20),

              // Total
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Subtotal (netto của sản phẩm)
                      pw.Text(
                        'Netto: ${CurrencyFormatter.formatPLN(priceCalculations['netto']!)}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 5),
                      
                      // Phí vận chuyển nếu có
                      if (priceCalculations['shippingTotal']! > 0) ...[
                        pw.Text(
                          'Dostawa: ${CurrencyFormatter.formatPLN(priceCalculations['shippingTotal']!)}',
                          style: pw.TextStyle(font: ttf),
                        ),
                        pw.SizedBox(height: 5),
                      ],
                      
                      // Tổng thuế
                      if (priceCalculations['totalTax']! > 0) ...[
                        pw.Text(
                          'Podatek: ${CurrencyFormatter.formatPLN(priceCalculations['totalTax']!)}',
                          style: pw.TextStyle(font: ttf),
                        ),
                        pw.SizedBox(height: 5),
                      ],
                      
                      // Đường kẻ ngăn cách
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.grey400,
                      ),
                      pw.SizedBox(height: 5),
                      
                      // Tổng cuối (brutto)
                      pw.Text(
                        'SUMA BRUTTO: ${CurrencyFormatter.formatPLN(priceCalculations['brutto']!)}',
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
            ];
        },
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
