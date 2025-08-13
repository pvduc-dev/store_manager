import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // Trên Android 10+ (API 29+), sử dụng quyền mới
    if (await _isAndroid10OrHigher()) {
      // Kiểm tra quyền quản lý file (Android 11+)
      if (await _isAndroid11OrHigher()) {
        // Thử quyền MANAGE_EXTERNAL_STORAGE trước
        PermissionStatus status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;
        
        status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
        
        // Nếu không được, thử quyền storage thông thường
        status = await Permission.storage.status;
        if (status.isGranted) return true;
        
        status = await Permission.storage.request();
        if (status.isGranted) return true;
        
        // Nếu quyền bị từ chối, hiển thị dialog giải thích
        if (status.isDenied || status.isPermanentlyDenied) {
          bool shouldOpenSettings = await _showPermissionDialog(context, 'quản lý file');
          if (shouldOpenSettings) {
            await openAppSettings();
          }
        }
        return false;
      } else {
        // Android 10: Sử dụng quyền truy cập media
        List<Permission> permissions = [
          Permission.storage,
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        // Kiểm tra quyền hiện tại
        Map<Permission, PermissionStatus> statuses = await permissions.request();
        
        // Kiểm tra xem có quyền nào được cấp không
        bool hasAnyPermission = statuses.values.any((status) => status.isGranted);
        if (hasAnyPermission) return true;
        
        // Nếu không có quyền nào, hiển thị dialog
        bool shouldOpenSettings = await _showPermissionDialog(context, 'truy cập bộ nhớ');
        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return false;
      }
    } else {
      // Android 9 trở xuống: Sử dụng quyền cũ
      PermissionStatus status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      status = await Permission.storage.request();
      if (status.isGranted) return true;
      
      if (status.isDenied || status.isPermanentlyDenied) {
        bool shouldOpenSettings = await _showPermissionDialog(context, 'truy cập bộ nhớ');
        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }
  }

  /// Kiểm tra và yêu cầu quyền truy cập Downloads
  static Future<bool> requestDownloadPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    try {
      // Kiểm tra quyền truy cập bộ nhớ trước
      bool hasStoragePermission = await requestStoragePermission(context);
      if (!hasStoragePermission) return false;

      // Kiểm tra quyền truy cập Downloads
      PermissionStatus status = await Permission.storage.status;
      if (status.isGranted) return true;

      // Yêu cầu quyền
      status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Lỗi khi yêu cầu quyền Downloads: $e');
      return false;
    }
  }

  /// Kiểm tra tất cả quyền cần thiết
  static Future<Map<String, bool>> checkAllPermissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      return {
        'storage': true,
        'downloads': true,
        'media': true,
      };
    }

    Map<String, bool> permissions = {};

    // Kiểm tra quyền storage
    permissions['storage'] = await Permission.storage.status.isGranted;
    
    // Kiểm tra quyền manage external storage (Android 11+)
    if (await _isAndroid11OrHigher()) {
      permissions['manage_external'] = await Permission.manageExternalStorage.status.isGranted;
    }
    
    // Kiểm tra quyền media (Android 10+)
    if (await _isAndroid10OrHigher()) {
      permissions['media'] = await Permission.photos.status.isGranted ||
                             await Permission.videos.status.isGranted ||
                             await Permission.audio.status.isGranted;
    }

    return permissions;
  }

  /// Yêu cầu tất cả quyền cần thiết
  static Future<bool> requestAllPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    try {
      // Yêu cầu quyền storage cơ bản
      bool hasStoragePermission = await requestStoragePermission(context);
      if (!hasStoragePermission) return false;

      // Yêu cầu quyền media nếu cần
      if (await _isAndroid10OrHigher()) {
        List<Permission> mediaPermissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        Map<Permission, PermissionStatus> statuses = await mediaPermissions.request();
        bool hasMediaPermission = statuses.values.any((status) => status.isGranted);
        
        if (!hasMediaPermission) {
          // Nếu không có quyền media, thử quyền storage thông thường
          PermissionStatus storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            bool shouldOpenSettings = await _showPermissionDialog(context, 'truy cập bộ nhớ');
            if (shouldOpenSettings) {
              await openAppSettings();
            }
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Lỗi khi yêu cầu tất cả quyền: $e');
      return false;
    }
  }

  /// Hiển thị dialog kiểm tra quyền
  static Future<void> showPermissionStatusDialog(BuildContext context) async {
    Map<String, bool> permissions = await checkAllPermissions(context);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Trạng thái quyền truy cập'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Storage: ${permissions['storage'] ?? false ? '✅' : '❌'}'),
                if (permissions.containsKey('manage_external'))
                  Text('Manage External: ${permissions['manage_external'] ?? false ? '✅' : '❌'}'),
                if (permissions.containsKey('media'))
                  Text('Media: ${permissions['media'] ?? false ? '✅' : '❌'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Mở cài đặt'),
              ),
            ],
          );
        },
      );
    }
  }

  static Future<bool> _isAndroid10OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Kiểm tra version Android
    return true; // Giả sử là Android 10+ để test
  }

  static Future<bool> _isAndroid11OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Kiểm tra version Android
    return true; // Giả sử là Android 11+ để test
  }

  static Future<bool> _showPermissionDialog(BuildContext context, String permissionType) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quyền truy cập bộ nhớ'),
          content: Text(
            'Ứng dụng cần quyền $permissionType để tải PDF về thiết bị. '
            'Vui lòng cấp quyền trong cài đặt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mở cài đặt'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
