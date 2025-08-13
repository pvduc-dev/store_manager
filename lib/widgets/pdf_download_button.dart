import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/permission_service.dart';

class PdfDownloadButton extends StatelessWidget {
  final String filename;
  final Future<List<int>> Function() generatePdf;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const PdfDownloadButton({
    super.key,
    required this.filename,
    required this.generatePdf,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: generatePdf(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Đang tạo PDF...'),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _downloadPdf(context, snapshot.data!),
              icon: const Icon(Icons.error),
              label: const Text('Lỗi tạo PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _downloadPdf(context, snapshot.data!),
              icon: const Icon(Icons.download),
              label: const Text('Tải PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.error),
            label: const Text('Không thể tạo PDF'),
          ),
        );
      },
    );
  }

  Future<void> _downloadPdf(BuildContext context, List<int> pdfBytes) async {
    try {
      // Kiểm tra quyền trước khi tải
      if (Platform.isAndroid) {
        // Yêu cầu tất cả quyền cần thiết
        final hasAllPermissions = await PermissionService.requestAllPermissions(context);
        if (!hasAllPermissions) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn cần cấp đầy đủ quyền để tải PDF.'),
                backgroundColor: Colors.red,
              ),
            );
            
            // Hiển thị dialog kiểm tra quyền
            await PermissionService.showPermissionStatusDialog(context);
          }
          onError?.call();
          return;
        }
      }

      // Tải PDF
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(pdfBytes),
        mimeType: MimeType.pdf,
        ext: 'pdf',
      );

      // Hiển thị thông báo thành công
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF đã được tải về thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      onSuccess?.call();
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      onError?.call();
    }
  }
}
