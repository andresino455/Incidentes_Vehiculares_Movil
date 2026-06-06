import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'registro_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notificacion_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool cargando = false;
  String error = '';

Future<void> _login() async {
  setState(() { cargando = true; error = ''; });
  final ok = await AuthService.loginUsuario(emailCtrl.text.trim(), passwordCtrl.text);
  if (!mounted) return;
  if (ok) {
    // Registrar token FCM después del login exitoso
    await _registrarTokenFCM();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  } else {
    setState(() { error = 'Credenciales incorrectas'; cargando = false; });
  }
}

Future<void> _registrarTokenFCM() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await NotificacionService.registrarTokenManual(token);
      print('[FCM] Token registrado después del login');
    }
  } catch (e) {
    print('[FCM] Error registrando token: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF534AB7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.car_repair, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Emergencias Vehiculares',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Iniciá sesión para continuar',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0DDD6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _campo('Email', emailCtrl, false),
                      const SizedBox(height: 16),
                      _campo('Contraseña', passwordCtrl, true),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBEB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(error, style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: cargando ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF534AB7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: cargando
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
                  child: const Text('¿No tenés cuenta? Registrate', style: TextStyle(color: Color(0xFF534AB7))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, bool obscure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: obscure ? '••••••••' : 'tu@email.com',
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF534AB7))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}