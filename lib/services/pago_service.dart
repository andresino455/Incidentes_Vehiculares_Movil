import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class PagoService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> crearPago({
    required String incidenteId,
    required double montoTotal,
    required String metodoPago,
  }) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/pagos/'),
      headers: await _headers(),
      body: jsonEncode({
        'incidente_id': incidenteId,
        'monto_total': montoTotal,
        'metodo_pago': metodoPago,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    return null;
  }

  static Future<List<dynamic>> getMisPagos() async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/pagos/mis-pagos'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }
}