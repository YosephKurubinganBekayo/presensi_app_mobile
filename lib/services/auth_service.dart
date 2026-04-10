import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    return "http://192.168.1.23:8000";
    // return "http://192.168.1.135:8000";
    // return "https://diagnosis-wiley-methods-edgar.trycloudflare.com";
  }

  // ================= LOGIN =================

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse("$baseUrl/api/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["access_token"]);
        await prefs.setString("role", data["user"]["role"]);
        await prefs.setString("name", data["user"]["name"]);

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ================= TOKEN =================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<Map<String, String>> authHeader() async {
    final token = await getToken();

    if (token == null) {
      return {"Content-Type": "application/json"};
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ================= GENERIC REQUEST =================

  static Future<http.Response> getWithAuth(String endpoint) async {
    final headers = await authHeader();
    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 401) {
      await logout();
    }

    return response;
  }

  static Future<http.Response> putWithAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await authHeader();
    final url = Uri.parse("$baseUrl$endpoint");

    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> postWithAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await authHeader();
    final url = Uri.parse("$baseUrl$endpoint");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await logout();
    }

    return response;
  }

  // ================= SESSION =================

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") != null;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("name");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================= MULTIPART REQUEST =================
  static Future<http.Response> multipartRequest(
    String endpoint, {
    required String filePath,
    required String fieldName,
  }) async {
    final token = await getToken();

    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl$endpoint"));

    request.headers["Authorization"] = "Bearer $token";

    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    var streamedResponse = await request.send();

    return await http.Response.fromStream(streamedResponse);
  }
}
