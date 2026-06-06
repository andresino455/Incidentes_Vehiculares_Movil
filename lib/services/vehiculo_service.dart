import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class VehiculoService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getMisVehiculos() async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/vehiculos/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>?> crearVehiculo(Map<String, dynamic> datos) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/vehiculos/'),
      headers: await _headers(),
      body: jsonEncode(datos),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    return null;
  }
}