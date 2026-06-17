import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // Returns the secure URL of the uploaded file, or null on failure.
  static Future<String?> uploadFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String resourceType, // 'image', 'video', 'raw' (for audio/files)
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) return null;

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset;

    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } else {
      return null;
    }

    final streamed = await request.send();
    if (streamed.statusCode == 200) {
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }
    return null;
  }

  static String resourceTypeFor(String messageType) {
    switch (messageType) {
      case 'image':
        return 'image';
      case 'video':
        return 'video';
      default:
        return 'raw';
    }
  }
}
