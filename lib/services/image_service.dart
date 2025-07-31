import 'dart:io';
import 'package:dio/dio.dart';

class ImageService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wp/v2/media';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<int?> uploadImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      final imageUploadResponse = await Dio().post(
        baseUrl,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'image/jpeg',
            'Content-Disposition': 'attachment; filename="$fileName"',
          },
        ),
        data: Stream.fromIterable(imageBytes.map((e) => [e])),
      );

      if (imageUploadResponse.statusCode == 201) {
        return imageUploadResponse.data['id'];
      } else {
        print('Error uploading image: ${imageUploadResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while uploading image: $e');
      return null;
    }
  }

  static Future<List<String>> getImages() async {
    final response = await Dio().get(
      baseUrl,
      options: Options(headers: {'Authorization': basicAuth}),
    );
    return response.data.map((e) => e['url']).toList();
  }
}
