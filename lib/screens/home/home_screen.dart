import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/websocket_service.dart';
import '../auth/login_screen.dart';
import '../incidente/reporte_screen.dart';
import '../incidente/mis_incidentes_screen.dart';
import '../vehiculo/mis_vehiculos_screen.dart';
import '../incidente/incidentes_offline_screen.dart';
import '../../services/offline_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _paginaActual = 0;
  List<Map<String, dynamic>> notificaciones = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _cargarNotificacionesGuardadas();
    _conectarWS();
  }

  Future<void> _cargarNotificacionesGuardadas() async {
    final guardadas = await WebSocketService.getNotificacionesGuardadas();
    if (mounted) setState(() => notificaciones = guardadas);
  }

  Future<void> _conectarWS() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final userId = payload['sub'];
      if (userId == null) return;

      WebSocketService.conectar('usuario', userId);
      _sub = WebSocketService.mensajes.listen((msg) {
        if (mounted) setState(() => notificaciones.insert(0, msg));
      });
    } catch (e) {
      print('[WS] Error al conectar: $e');
    }
  }

  Future<void> _limpiarNotificaciones() async {
    await WebSocketService.limpiarNotificaciones();
    if (mounted) setState(() => notificaciones.clear());
  }

  @override
  void dispose() {
    _sub?.cancel();
    WebSocketService.desconectar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _paginaActual,
        children: [
          _InicioTab(
            notificaciones: notificaciones,
            onLimpiar: _limpiarNotificaciones,
          ),
          const MisIncidentesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: (i) => setState(() => _paginaActual = i),
        selectedItemColor: const Color(0xFF534AB7),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Mis incidentes',
          ),
        ],
      ),
    );
  }
}

class _InicioTab extends StatelessWidget {
  final List<Map<String, dynamic>> notificaciones;
  final VoidCallback onLimpiar;

  const _InicioTab({required this.notificaciones, required this.onLimpiar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Emergencias Vehiculares',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF534AB7),
                ),
                onPressed: () => _mostrarNotificaciones(context),
              ),
              if (notificaciones.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD85A30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        notificaciones.length > 9
                            ? '9+'
                            : '${notificaciones.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              WebSocketService.desconectar();
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notificaciones.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC4BEF5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Color(0xFF534AB7),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Notificaciones',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD85A30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notificaciones.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: onLimpiar,
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF534AB7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...notificaciones
                        .take(3)
                        .map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: _colorNotif(n['tipo']),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['titulo'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        n['mensaje'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (notificaciones.length > 3)
                      GestureDetector(
                        onTap: () => _mostrarNotificaciones(context),
                        child: Text(
                          '+ ${notificaciones.length - 3} más — Ver todas',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF534AB7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF534AB7), Color(0xFF3C3489)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.car_repair, color: Colors.white, size: 32),
                  SizedBox(height: 12),
                  Text(
                    '¿Tenés una emergencia?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Reportá tu problema y te conectamos con un taller cercano.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReporteScreen()),
              ),
              icon: const Icon(Icons.add_alert),
              label: const Text(
                'Reportar emergencia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD85A30),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisIncidentesScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Ver mis incidentes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF534AB7),
                side: const BorderSide(color: Color(0xFF534AB7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisVehiculosScreen()),
              ),
              icon: const Icon(Icons.directions_car),
              label: const Text('Mis vehículos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF534AB7),
                side: const BorderSide(color: Color(0xFF534AB7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<int>(
              future: OfflineService.contarPendientes(),
              builder: (context, snapshot) {
                final pendientes = snapshot.data ?? 0;
                return Stack(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncidentesOfflineScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.cloud_off),
                      label: const Text('Emergencias guardadas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pendientes > 0
                            ? const Color(0xFFB7791F)
                            : const Color(0xFF534AB7),
                        side: BorderSide(
                          color: pendientes > 0
                              ? const Color(0xFFB7791F)
                              : const Color(0xFF534AB7),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (pendientes > 0)
                      Positioned(
                        right: 12,
                        top: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB7791F),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$pendientes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.speed,
                    'Respuesta rápida',
                    'Talleres cercanos listos',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.verified_user,
                    'Seguro',
                    'Talleres verificados',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.location_on,
                    'GPS en tiempo real',
                    'Seguí tu asistencia',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(Icons.payment, 'Pago fácil', 'Desde la app'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorNotif(String? tipo) {
    switch (tipo) {
      case 'taller_asignado':
        return const Color(0xFF1D9E75);
      case 'atendido':
        return const Color(0xFF276749);
      case 'cancelado':
        return const Color(0xFFC53030);
      default:
        return const Color(0xFF534AB7);
    }
  }

  void _mostrarNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD85A30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${notificaciones.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      onLimpiar();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Limpiar todo',
                      style: TextStyle(color: Color(0xFF534AB7)),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: notificaciones.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sin notificaciones',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notificaciones.length,
                        itemBuilder: (_, i) {
                          final n = notificaciones[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _colorNotif(n['tipo']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _colorNotif(n['tipo']).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _colorNotif(n['tipo']),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _iconoNotif(n['tipo']),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['titulo'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        n['mensaje'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconoNotif(String? tipo) {
    switch (tipo) {
      case 'taller_asignado':
        return Icons.directions_car;
      case 'atendido':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Widget _infoCard(IconData icono, String titulo, String subtitulo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: const Color(0xFF534AB7), size: 22),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
