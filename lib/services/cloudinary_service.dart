import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:pulsepages/constants/constants.dart';

class CloudinaryService {
  static const String cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/${Constants.cloudinaryCloudName}/image/upload';

  static const String cloudinaryDestroyUrl =
      'https://api.cloudinary.com/v1_1/${Constants.cloudinaryCloudName}/image/destroy';

  static String uploadPreset = Constants.cloudinaryUploadPreset;

  static Future<String> uploadImage(File image) async {
    try {
      final uri = Uri.parse(cloudinaryUrl);

      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = uploadPreset
            ..fields['folder'] = 'pulsepages_images';

      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseData.body);
        final secureUrl = data['secure_url'];
        return secureUrl;
      } else {
        throw Exception(
          'Image upload failed. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final publicId = _extractPublicId(imageUrl);

      if (publicId == null) {
        throw Exception('Invalid image URL: Public ID not found');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final stringToSign =
          'public_id=$publicId&timestamp=$timestamp${Constants.cloudinaryApiSecret}';

      final signature = sha1.convert(utf8.encode(stringToSign)).toString();

      final Map<String, String> body = {
        'public_id': publicId,
        'api_key': Constants.cloudinaryApiKey,
        'timestamp': timestamp,
        'signature': signature,
      };

      final uri = Uri.parse(cloudinaryDestroyUrl);
      final response = await http.post(uri, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['result'] == 'ok') {
          return;
        } else {
          throw Exception('Failed to delete image: ${data['result']}');
        }
      } else {
        throw Exception(
          'Failed to delete image. Status code: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  static String? _extractPublicId(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      final folderIndex = segments.indexOf('pulsepages_images');
      if (folderIndex == -1 || folderIndex >= segments.length - 1) {
        return null;
      }

      final publicId =
          'pulsepages_images/${segments.sublist(folderIndex + 1).join('/')}';

      if (publicId.contains('.')) {
        return publicId.substring(0, publicId.lastIndexOf('.'));
      }
      return publicId;
    } catch (e) {
      return null;
    }
  }
}
