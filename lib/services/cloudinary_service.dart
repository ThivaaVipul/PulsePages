import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:pulsepages/constants/constants.dart';

class CloudinaryService {
  static const String cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/${Constants.cloudinaryCloudName}/image/upload';

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
}
