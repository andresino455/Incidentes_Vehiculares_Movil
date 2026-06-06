import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class CalificacionService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> calificar({
    required String incidenteId,
    required int puntuacion,
    String? comentario,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.apiUrl}/calificaciones/'),
        headers: await _headers(),
        body: jsonEncode({
          'incidente_id': incidenteId,
          'puntuacion': puntuacion,
          'comentario': comentario,
        }),
      );
      if (res.statusCode == 201) return jsonDecode(res.body);
      return null;
    } catch (e) {
      return null;
    }
  }
}