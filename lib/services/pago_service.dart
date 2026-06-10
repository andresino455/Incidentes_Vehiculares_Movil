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

  // 1. Crear pago directo (Local / Manual)
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

  // 2. Obtener el historial de pagos de un cliente
  static Future<List<dynamic>> getMisPagos() async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/pagos/mis-pagos'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // 3. Obtener el historial de cobros y el resumen financiero de un taller
  static Future<Map<String, dynamic>?> getMisCobros() async {
    final res = await http.get(
      Uri.parse('${Config.apiUrl}/pagos/mis-cobros'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // 4. Iniciar el flujo de Stripe creando un Payment Intent
  static Future<Map<String, dynamic>?> crearPaymentIntent({
    required String incidenteId,
    required double montoTotal,
    required String metodoPago,
  }) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/pagos/crear-intent'),
      headers: await _headers(),
      body: jsonEncode({
        'incidente_id': incidenteId,
        'monto_total': montoTotal,
        'metodo_pago': metodoPago,
      }),
    );
    // Este endpoint de FastAPI responde con un status 200 por defecto al retornar el diccionario
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // 5. Confirmar el pago en el backend una vez que Stripe procesó la tarjeta en la app
  static Future<Map<String, dynamic>?> confirmarPago({
    required String incidenteId,
    required double montoTotal,
    required String metodoPago,
    required String paymentIntentId,
  }) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/pagos/confirmar'),
      headers: await _headers(),
      body: jsonEncode({
        'incidente_id': incidenteId,
        'monto_total': montoTotal,
        'metodo_pago': metodoPago,
        'payment_intent_id': paymentIntentId,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    return null;
  }
}