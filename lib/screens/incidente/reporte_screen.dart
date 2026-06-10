import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../../services/incidente_service.dart';
import '../../services/vehiculo_service.dart';
import '../../services/offline_service.dart';

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  final descripcionCtrl = TextEditingController();
  final MapController _mapController = MapController();

  List<dynamic> vehiculos = [];
  String? vehiculoSeleccionado;
  String? tipoProblema;
  Position? ubicacion;
  File? imagen;
  bool cargando = false;
  bool obtenendoUbicacion = false;
  String error = '';
  String exito = '';
  bool _sinConexion = false;
  bool _ubicacionCacheada = false;

  // Audio
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _grabando = false;
  bool _recorderIniciado = false;
  String? _rutaAudio;
  Duration _duracionGrabacion = Duration.zero;

  final tipos = ['bateria', 'llanta', 'choque', 'motor', 'otros'];

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
    _obtenerUbicacion();
    _iniciarRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarRecorder() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _recorder.openRecorder();
      setState(() => _recorderIniciado = true);
    }
  }

  Future<void> _cargarVehiculos() async {
    final conectado = await OfflineService.hayConexion();
    final prefs = await SharedPreferences.getInstance();

    if (conectado) {
      try {
        final data = await VehiculoService.getMisVehiculos();
        // Guardar en caché
        await prefs.setString('vehiculos_cache', jsonEncode(data));
        setState(() {
          vehiculos = data;
          _sinConexion = false;
        });
        return;
      } catch (_) {}
    }

    // Sin conexión o error: cargar del caché
    final cache = prefs.getString('vehiculos_cache');
    if (cache != null) {
      setState(() {
        vehiculos = jsonDecode(cache);
        _sinConexion = !conectado;
      });
    } else {
      setState(() {
        _sinConexion = !conectado;
        error = conectado
            ? 'Error al cargar vehículos'
            : 'Sin conexión y sin datos en caché. Abrí la app con internet al menos una vez.';
      });
    }
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => obtenendoUbicacion = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) {
        setState(() {
          error = 'Permiso de ubicación denegado';
          obtenendoUbicacion = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      // Guardar última ubicación conocida
      await prefs.setDouble('ultima_lat', pos.latitude);
      await prefs.setDouble('ultima_lng', pos.longitude);

      setState(() {
        ubicacion = pos;
        obtenendoUbicacion = false;
        _ubicacionCacheada = false;
      });
      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      } catch (_) {}
    } catch (e) {
      // Sin GPS: usar última ubicación conocida
      final lat = prefs.getDouble('ultima_lat');
      final lng = prefs.getDouble('ultima_lng');
      if (lat != null && lng != null) {
        setState(() {
          ubicacion = Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _ubicacionCacheada = true;
          obtenendoUbicacion = false;
        });
        try {
          _mapController.move(LatLng(lat, lng), 15);
        } catch (_) {}
      } else {
        setState(() {
          error = 'No se pudo obtener la ubicación';
          obtenendoUbicacion = false;
        });
      }
    }
  }

  Future<void> _iniciarGrabacion() async {
    if (!_recorderIniciado) {
      await _iniciarRecorder();
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final ruta =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.startRecorder(toFile: ruta, codec: Codec.aacMP4);

      setState(() {
        _grabando = true;
        _rutaAudio = ruta;
        _duracionGrabacion = Duration.zero;
      });

      Stream.periodic(const Duration(seconds: 1)).listen((_) {
        if (_grabando && mounted) {
          setState(() {
            _duracionGrabacion += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      setState(() => error = 'Error al iniciar la grabación: $e');
    }
  }

  Future<void> _detenerGrabacion() async {
    try {
      await _recorder.stopRecorder();
      setState(() => _grabando = false);
    } catch (e) {
      setState(() => error = 'Error al detener la grabación');
    }
  }

  void _eliminarAudio() {
    if (_rutaAudio != null) {
      try {
        File(_rutaAudio!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _rutaAudio = null;
      _duracionGrabacion = Duration.zero;
    });
  }

  String _formatDuracion(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final seg = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) setState(() => imagen = File(picked.path));
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => imagen = File(picked.path));
  }

  Future<void> _enviarReporte() async {
    if (vehiculoSeleccionado == null) {
      setState(() => error = 'Seleccioná un vehículo');
      return;
    }
    if (ubicacion == null) {
      setState(() => error = 'Esperá a que se obtenga tu ubicación');
      return;
    }
    if (_grabando) await _detenerGrabacion();

    setState(() {
      cargando = true;
      error = '';
    });

    final tieneInternet = await OfflineService.hayConexion();

    if (!tieneInternet) {
      await OfflineService.guardarIncidenteLocal(
        vehiculoId: vehiculoSeleccionado!,
        latitud: ubicacion!.latitude,
        longitud: ubicacion!.longitude,
        descripcionTexto: descripcionCtrl.text.trim(),
        tipoProblema: tipoProblema,
        imagenPath: imagen?.path,
        audioPath: _rutaAudio,
      );
      setState(() {
        exito =
            '⚠️ Sin conexión — Emergencia guardada localmente. Se enviará cuando vuelva la conexión.';
        cargando = false;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // Con internet — enviar normalmente
    try {
      final incidente = await IncidenteService.crearIncidente({
        'vehiculo_id': vehiculoSeleccionado,
        'latitud': ubicacion!.latitude,
        'longitud': ubicacion!.longitude,
        'descripcion_texto': descripcionCtrl.text.trim(),
        'tipo_problema': tipoProblema,
      });

      if (incidente == null) {
        // Falló el envío, guardar offline
        await OfflineService.guardarIncidenteLocal(
          vehiculoId: vehiculoSeleccionado!,
          latitud: ubicacion!.latitude,
          longitud: ubicacion!.longitude,
          descripcionTexto: descripcionCtrl.text.trim(),
          tipoProblema: tipoProblema,
          imagenPath: imagen?.path,
          audioPath: _rutaAudio,
        );
        setState(() {
          exito = '⚠️ No se pudo conectar. Emergencia guardada localmente.';
          cargando = false;
        });
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      if (imagen != null)
        await IncidenteService.subirImagen(incidente['id'], imagen!);
      if (_rutaAudio != null)
        await IncidenteService.subirAudio(incidente['id'], _rutaAudio!);

      setState(() {
        exito = '✅ Emergencia reportada correctamente';
        cargando = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Error inesperado, guardar offline
      await OfflineService.guardarIncidenteLocal(
        vehiculoId: vehiculoSeleccionado!,
        latitud: ubicacion!.latitude,
        longitud: ubicacion!.longitude,
        descripcionTexto: descripcionCtrl.text.trim(),
        tipoProblema: tipoProblema,
        imagenPath: imagen?.path,
        audioPath: _rutaAudio,
      );
      setState(() {
        exito = '⚠️ Error de conexión. Emergencia guardada localmente.';
        cargando = false;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reportar emergencia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner sin conexión
            if (_sinConexion)
              _buildBanner(
                '⚠️ Modo sin conexión — datos cargados del caché',
                const Color(0xFFFAEEDA),
                const Color(0xFFBA7517),
              ),

            // Ubicación y mapa
            _seccion(
              icono: Icons.location_on,
              titulo: 'Tu ubicación',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  obtenendoUbicacion
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Obteniendo ubicación...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : ubicacion != null
                      ? Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _ubicacionCacheada
                                  ? const Color(0xFFBA7517)
                                  : const Color(0xFF1D9E75),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lat: ${ubicacion!.latitude.toStringAsFixed(4)}, Lng: ${ubicacion!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _ubicacionCacheada
                                      ? const Color(0xFFBA7517)
                                      : const Color(0xFF1D9E75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _obtenerUbicacion,
                              child: const Text(
                                'Actualizar',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        )
                      : TextButton.icon(
                          onPressed: _obtenerUbicacion,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Obtener ubicación'),
                        ),

                  // Aviso ubicación cacheada
                  if (_ubicacionCacheada)
                    _buildBanner(
                      '📍 Usando última ubicación conocida',
                      const Color(0xFFFAEEDA),
                      const Color(0xFFBA7517),
                    ),

                  if (ubicacion != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              ubicacion!.latitude,
                              ubicacion!.longitude,
                            ),
                            initialZoom: 15,
                            onTap: (tapPos, point) {
                              setState(() {
                                ubicacion = Position(
                                  latitude: point.latitude,
                                  longitude: point.longitude,
                                  timestamp: DateTime.now(),
                                  accuracy: 0,
                                  altitude: 0,
                                  altitudeAccuracy: 0,
                                  heading: 0,
                                  headingAccuracy: 0,
                                  speed: 0,
                                  speedAccuracy: 0,
                                );
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.mobile',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    ubicacion!.latitude,
                                    ubicacion!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Color(0xFFD85A30),
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tocá el mapa para ajustar la ubicación exacta',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Vehículo
            _seccion(
              icono: Icons.directions_car,
              titulo: 'Vehículo',
              child: vehiculos.isEmpty
                  ? Text(
                      _sinConexion
                          ? 'Sin conexión y sin vehículos en caché. Abrí la app con internet al menos una vez.'
                          : 'No tenés vehículos registrados. Registrá uno primero.',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    )
                  : DropdownButtonFormField<String>(
                      value: vehiculoSeleccionado,
                      decoration: _inputDeco('Seleccioná tu vehículo'),
                      items: vehiculos.map<DropdownMenuItem<String>>((v) {
                        return DropdownMenuItem(
                          value: v['id'].toString(),
                          child: Text(
                            '${v['marca']} ${v['modelo']} - ${v['placa']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => vehiculoSeleccionado = val),
                    ),
            ),

            const SizedBox(height: 16),

            // Tipo de problema
            _seccion(
              icono: Icons.build,
              titulo: 'Tipo de problema',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tipos.map((t) {
                  final seleccionado = tipoProblema == t;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => tipoProblema = seleccionado ? null : t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? const Color(0xFFEEEDFE)
                            : Colors.white,
                        border: Border.all(
                          color: seleccionado
                              ? const Color(0xFF534AB7)
                              : const Color(0xFFDDDDDD),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: seleccionado
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: seleccionado
                              ? const Color(0xFF534AB7)
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Descripción
            _seccion(
              icono: Icons.description,
              titulo: 'Descripción',
              child: TextField(
                controller: descripcionCtrl,
                maxLines: 3,
                decoration: _inputDeco('Describí brevemente el problema...'),
              ),
            ),

            const SizedBox(height: 16),

            // Audio
            _seccion(
              icono: Icons.mic,
              titulo: 'Grabar audio (opcional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_rutaAudio != null && !_grabando) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1D9E75).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1D9E75),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Audio grabado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF1D9E75),
                                  ),
                                ),
                                Text(
                                  'Duración: ${_formatDuracion(_duracionGrabacion)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _eliminarAudio,
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_grabando) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD85A30).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Color(0xFFD85A30),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Grabando...',
                            style: TextStyle(
                              color: Color(0xFFD85A30),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuracion(_duracionGrabacion),
                            style: const TextStyle(
                              color: Color(0xFFD85A30),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _grabando
                              ? _detenerGrabacion
                              : (_rutaAudio == null ? _iniciarGrabacion : null),
                          icon: Icon(
                            _grabando ? Icons.stop : Icons.mic,
                            size: 18,
                          ),
                          label: Text(
                            _grabando
                                ? 'Detener grabación'
                                : _rutaAudio != null
                                ? 'Audio listo'
                                : 'Iniciar grabación',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _grabando
                                ? const Color(0xFFD85A30)
                                : _rutaAudio != null
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFF534AB7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Describí verbalmente el problema para que la IA lo analice',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Foto
            _seccion(
              icono: Icons.photo_camera,
              titulo: 'Foto del vehículo (opcional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (imagen != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        imagen!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => imagen = null),
                      child: const Text(
                        'Quitar foto',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _tomarFoto,
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Cámara'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF534AB7),
                            side: const BorderSide(color: Color(0xFF534AB7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarFoto,
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Galería'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF534AB7),
                            side: const BorderSide(color: Color(0xFF534AB7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFFA32D2D),
                    fontSize: 13,
                  ),
                ),
              ),

            if (exito.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exito,
                  style: const TextStyle(
                    color: Color(0xFF276749),
                    fontSize: 13,
                  ),
                ),
              ),

            ElevatedButton.icon(
              onPressed: cargando ? null : _enviarReporte,
              icon: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                cargando ? 'Enviando...' : 'Enviar emergencia',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(String mensaje, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.4)),
      ),
      child: Text(mensaje, style: TextStyle(color: textColor, fontSize: 13)),
    );
  }

  Widget _seccion({
    required IconData icono,
    required String titulo,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: const Color(0xFF534AB7)),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF534AB7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
