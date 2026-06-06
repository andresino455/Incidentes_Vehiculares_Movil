import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool cargando = false;
  String error = '';
  String exito = '';

  Future<void> _registrar() async {
    if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      setState(() => error = 'Completá los campos obligatorios');
      return;
    }
    setState(() { cargando = true; error = ''; });
    final res = await AuthService.registroUsuario({
      'nombre': nombreCtrl.text.trim(),
      'apellido': apellidoCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'telefono': telefonoCtrl.text.trim(),
      'password': passwordCtrl.text,
    });
    if (!mounted) return;
    if (res.containsKey('id')) {
      setState(() { exito = 'Cuenta creada. Iniciá sesión.'; cargando = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      setState(() {
        error = res['detail'] ?? 'Error al registrar';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Crear cuenta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Completá tus datos', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
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
                    _campo('Nombre *', nombreCtrl, false),
                    const SizedBox(height: 14),
                    _campo('Apellido *', apellidoCtrl, false),
                    const SizedBox(height: 14),
                    _campo('Email *', emailCtrl, false),
                    const SizedBox(height: 14),
                    _campo('Teléfono', telefonoCtrl, false),
                    const SizedBox(height: 14),
                    _campo('Contraseña *', passwordCtrl, true),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFCEBEB), borderRadius: BorderRadius.circular(8)),
                        child: Text(error, style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
                      ),
                    ],
                    if (exito.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(8)),
                        child: Text(exito, style: const TextStyle(color: Color(0xFF276749), fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: cargando ? null : _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF534AB7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: cargando
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
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