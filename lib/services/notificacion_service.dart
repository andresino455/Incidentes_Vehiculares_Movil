import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[FCM] Mensaje en background: ${message.notification?.title}');
}

class NotificacionService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'emergencias_canal',
    'Emergencias Vehiculares',
    description: 'Notificaciones de la plataforma',
    importance: Importance.high,
  );

  static Future<void> inicializar() async {
    await Firebase.initializeApp();
    print('[FCM] Firebase inicializado');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotif.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_canal);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Borrar token anterior y obtener uno nuevo
    await FirebaseMessaging.instance.deleteToken();
    final String? token = await FirebaseMessaging.instance.getToken();
    print('[FCM] Token: ${token != null ? token.substring(0, 30) : "NULL"}');
    if (token != null) {
      await _registrarToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_registrarToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] Mensaje foreground: ${message.notification?.title}');
      _mostrarNotificacionLocal(message);
    });
  }

  static Future<void> _registrarToken(String token) async {
    try {
      final String? authToken = await AuthService.getToken();
      if (authToken == null) return;

      await http.post(
        Uri.parse('${Config.apiUrl}/notificaciones/registrar-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token, 'plataforma': 'android'}),
      );
      print('[FCM] Token registrado en el servidor');
    } catch (e) {
      print('[FCM] Error registrando token: $e');
    }
  }

  static Future<void> _mostrarNotificacionLocal(RemoteMessage message) async {
    final RemoteNotification? notif = message.notification;
    if (notif == null) return;

    await _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> registrarTokenManual(String token) async {
    await _registrarToken(token);
  }
}
