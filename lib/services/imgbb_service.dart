import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  // Your provided API Key
  static const String _apiKey = '5558a317e6889711facf0a9502619fc0'; 

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
      );

      // This line prevents the "No host specified" error
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['data']['url']; // Direct link to image
      } else {
        print('ImgBB Upload Failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('ImgBB Exception: $e');
      return null;
    }
  }
}