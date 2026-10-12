import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // CHANGE THIS TO YOUR NGROK URL
  static const String baseUrl = "....";

  static Future<Map<String, dynamic>> predictVideo(File videoFile) async {
    try {
      var uri = Uri.parse("$baseUrl/predict");

      var request = http.MultipartRequest("POST", uri);
      request.files.add(await http.MultipartFile.fromPath("file", videoFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {"error": "Server Error", "details": responseBody};
      }
    } catch (e) {
      return {"error": "Client Error", "details": e.toString()};
    }
  }
}
