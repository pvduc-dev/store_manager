import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';

class PdfViewer extends StatefulWidget {
  final List<int> pdfBytes;
  final String filename;

  const PdfViewer({
    super.key,
    required this.pdfBytes,
    required this.filename,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Xem trước: ${widget.filename}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // Nút in
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPdf(),
            tooltip: 'In PDF',
          ),
          // Nút chia sẻ
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(),
            tooltip: 'Chia sẻ PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar với các tùy chọn zoom
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                // Nút zoom out
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {
                    setState(() {
                      if (_zoomLevel > 0.5) {
                        _zoomLevel -= 0.1;
                      }
                    });
                  },
                  tooltip: 'Thu nhỏ',
                ),
                // Hiển thị mức zoom hiện tại
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Nút zoom in
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {
                    setState(() {
                      if (_zoomLevel < 3.0) {
                        _zoomLevel += 0.1;
                      }
                    });
                  },
                  tooltip: 'Phóng to',
                ),
                // Nút reset zoom
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _zoomLevel = 1.0;
                    });
                  },
                  tooltip: 'Đặt lại zoom',
                ),
              ],
            ),
          ),
          // Nội dung PDF
          Expanded(
            child: PdfPreview(
              build: (format) async => Uint8List.fromList(widget.pdfBytes),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              maxPageWidth: 700 * _zoomLevel,
              actions: [
                PdfPreviewAction(
                  icon: const Icon(Icons.print),
                  onPressed: (context, pdfBytes, format) => _printPdf(),
                ),
                PdfPreviewAction(
                  icon: const Icon(Icons.share),
                  onPressed: (context, pdfBytes, format) => _sharePdf(),
                ),
              ],
              pdfFileName: widget.filename,
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              previewPageMargin: const EdgeInsets.all(16),
              scrollViewDecoration: BoxDecoration(
                color: Colors.grey[100],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf() async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => Uint8List.fromList(widget.pdfBytes),
        name: widget.filename,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể in PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(widget.pdfBytes),
        filename: widget.filename,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}
