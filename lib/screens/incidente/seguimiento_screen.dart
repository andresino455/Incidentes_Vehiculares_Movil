import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/websocket_service.dart';

class SeguimientoScreen extends StatefulWidget {
  final Map<String, dynamic> incidente;

  const SeguimientoScreen({super.key, required this.incidente});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  final MapController _mapController = MapController();
  StreamSubscription? _sub;

  LatLng? _ubicacionTecnico;
  LatLng? _ubicacionUsuario;
  double? _distanciaKm;
  int? _minutosEstimados;
  final Distance _distanceCalc = const Distance();

  @override
  void initState() {
    super.initState();
    _inicializar();
    _escucharUbicacion();
  }

  void _inicializar() {
    final inc = widget.incidente;

    if (inc['latitud'] != null && inc['longitud'] != null) {
      _ubicacionUsuario = LatLng(
        double.parse(inc['latitud'].toString()),
        double.parse(inc['longitud'].toString()),
      );
    }

    final tecnico = inc['tecnico'];
    if (tecnico != null &&
        tecnico['latitud_actual'] != null &&
        tecnico['longitud_actual'] != null) {
      _ubicacionTecnico = LatLng(
        double.parse(tecnico['latitud_actual'].toString()),
        double.parse(tecnico['longitud_actual'].toString()),
      );
    }

    _calcularTiempoEstimado();
  }

  void _escucharUbicacion() {
    _sub = WebSocketService.mensajes.listen((msg) {
      if (msg['tipo'] == 'ubicacion_tecnico' && mounted) {
        setState(() {
          _ubicacionTecnico = LatLng(
            double.parse(msg['latitud'].toString()),
            double.parse(msg['longitud'].toString()),
          );
        });
        _calcularTiempoEstimado();
        if (_ubicacionTecnico != null) {
          _mapController.move(_ubicacionTecnico!, 14);
        }
      }
    });
  }

  void _calcularTiempoEstimado() {
    if (_ubicacionTecnico == null || _ubicacionUsuario == null) return;
    final metros = _distanceCalc.as(
      LengthUnit.Meter,
      _ubicacionTecnico!,
      _ubicacionUsuario!,
    );
    setState(() {
      _distanciaKm = metros / 1000;
      // Velocidad promedio en ciudad: 30 km/h
      _minutosEstimados = ((_distanciaKm! / 30) * 60).ceil();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tecnico = widget.incidente['tecnico'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Técnico en camino',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Info del técnico
          if (tecnico != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEEDFE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${tecnico['nombre'][0]}${tecnico['apellido'][0]}',
                        style: const TextStyle(
                          color: Color(0xFF534AB7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tecnico['nombre']} ${tecnico['apellido']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (tecnico['telefono'] != null)
                          Text(
                            tecnico['telefono'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF534AB7),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'En camino',
                          style: TextStyle(
                            color: Color(0xFF534AB7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Mapa
          Expanded(
            child: _ubicacionUsuario == null
                ? const Center(
                    child: Text(
                      'Cargando mapa...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _ubicacionTecnico ?? _ubicacionUsuario!,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          // Marcador del usuario
                          Marker(
                            point: _ubicacionUsuario!,
                            width: 50,
                            height: 50,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFD85A30),
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                          // Marcador del técnico
                          if (_ubicacionTecnico != null)
                            Marker(
                              point: _ubicacionTecnico!,
                              width: 50,
                              height: 50,
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.engineering,
                                    color: Color(0xFF534AB7),
                                    size: 36,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Línea entre técnico y usuario
                      if (_ubicacionTecnico != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [_ubicacionTecnico!, _ubicacionUsuario!],
                              color:
                                  const Color(0xFF534AB7).withOpacity(0.5),
                              strokeWidth: 3,
                              isDotted: true,
                            ),
                          ],
                        ),
                    ],
                  ),
          ),

          // Tiempo estimado + leyenda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Tiempo estimado
                if (_minutosEstimados != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF534AB7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _minutosEstimados! <= 1
                              ? 'El técnico está llegando'
                              : 'Tiempo estimado: $_minutosEstimados min  ·  ${_distanciaKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: Color(0xFF534AB7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Leyenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _leyendaItem(
                      Icons.location_pin,
                      const Color(0xFFD85A30),
                      'Tu ubicación',
                    ),
                    _leyendaItem(
                      Icons.engineering,
                      const Color(0xFF534AB7),
                      'Técnico',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leyendaItem(IconData icono, Color color, String label) {
    return Row(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}