import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class IncidenteService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getMisIncidentes() async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/incidentes/mis-incidentes'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>?> getDetalle(String id) async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/incidentes/$id'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<Map<String, dynamic>?> crearIncidente(
    Map<String, dynamic> datos,
  ) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/incidentes/'),
      headers: await _headers(),
      body: jsonEncode(datos),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> subirImagen(String incidenteId, File imagen) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.apiUrl}/evidencias/imagen/$incidenteId'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('archivo', imagen.path),
    );
    final res = await request.send();
    return res.statusCode == 200;
  }

  static Future<List<dynamic>> getHistorial(String id) async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/incidentes/$id/historial'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> subirAudio(String incidenteId, String rutaAudio) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.apiUrl}/evidencias/audio/$incidenteId'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('archivo', rutaAudio));
    final res = await request.send();
    return res.statusCode == 200;
  }
}
