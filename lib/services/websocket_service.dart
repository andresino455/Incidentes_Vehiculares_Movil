import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _conectado = false;
  static String _clienteIdActual = '';
  static String _tipoActual = '';

  static Stream<Map<String, dynamic>> get mensajes => _controller.stream;

  static void conectar(String tipo, String clienteId) {
    // Si ya está conectado con el mismo cliente no reconectar
    if (_conectado && _clienteIdActual == clienteId) {
      print('[WS] Ya conectado, ignorando');
      return;
    }

    // Cerrar conexión anterior si existe
    _channel?.sink.close();
    _conectado = false;

    _clienteIdActual = clienteId;
    _tipoActual = tipo;

    final url = Config.apiUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$url/ws/$tipo/$clienteId'),
      );

      _conectado = true;

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data) as Map<String, dynamic>;
            _guardarNotificacion(msg);
            _controller.add(msg);
          } catch (e) {
            print('[WS] Error parseando: $e');
          }
        },
        onDone: () {
          print('[WS] Desconectado, reconectando en 3s...');
          _conectado = false;
          Future.delayed(const Duration(seconds: 3), () {
            if (!_conectado && _clienteIdActual.isNotEmpty) {
              conectar(_tipoActual, _clienteIdActual);
            }
          });
        },
        onError: (e) {
          print('[WS] Error: $e');
          _conectado = false;
        },
        cancelOnError: false,
      );
      print('[WS] Conectado como $tipo/$clienteId');
    } catch (e) {
      _conectado = false;
      print('[WS] Error conectando: $e');
    }
  }

  static Future<void> _guardarNotificacion(Map<String, dynamic> msg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList('notificaciones') ?? [];
      lista.insert(0, jsonEncode(msg));
      if (lista.length > 50) lista.removeLast();
      await prefs.setStringList('notificaciones', lista);
    } catch (e) {
      print('[WS] Error guardando notificación: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotificacionesGuardadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList('notificaciones') ?? [];
      return lista
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> limpiarNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notificaciones');
  }

  static void desconectar() {
    _clienteIdActual = '';
    _conectado = false;
    _channel?.sink.close();
    _channel = null;
  }
}