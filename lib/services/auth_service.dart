import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static Future<Map<String, dynamic>> registroUsuario(Map<String, dynamic> datos) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/auth/registro-usuario'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    return jsonDecode(res.body);
  }

  static Future<bool> loginUsuario(String email, String password) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/auth/login-usuario'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      await prefs.setString('tipo', data['tipo_usuario']);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('tipo');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}