import 'package:flutter/material.dart';
import '../../services/incidente_service.dart';
import '../pago/pago_screen.dart';
import '../calificacion/calificacion_screen.dart';
import 'seguimiento_screen.dart';
import 'cotizaciones_screen.dart';

class DetalleIncidenteScreen extends StatefulWidget {
  final String incidenteId;
  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  State<DetalleIncidenteScreen> createState() => _DetalleIncidenteScreenState();
}

class _DetalleIncidenteScreenState extends State<DetalleIncidenteScreen> {
  Map<String, dynamic>? incidente;
  List<dynamic> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final inc = await IncidenteService.getDetalle(widget.incidenteId);
    final hist = await IncidenteService.getHistorial(widget.incidenteId);
    setState(() {
      incidente = inc;
      historial = hist;
      cargando = false;
    });
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFB7791F);
      case 'en_proceso':
        return const Color(0xFF534AB7);
      case 'atendido':
        return const Color(0xFF276749);
      case 'cancelado':
        return const Color(0xFFC53030);
      default:
        return Colors.grey;
    }
  }

  Color _bgEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFFFFAF0);
      case 'en_proceso':
        return const Color(0xFFEEEDFE);
      case 'atendido':
        return const Color(0xFFF0FFF4);
      case 'cancelado':
        return const Color(0xFFFFF0F0);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
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
          'Detalle del incidente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF534AB7)),
            onPressed: _cargar,
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF534AB7)),
            )
          : incidente == null
          ? const Center(child: Text('No se pudo cargar el incidente'))
          : RefreshIndicator(
              onRefresh: _cargar,
              color: const Color(0xFF534AB7),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Estado actual
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _bgEstado(incidente!['estado']),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _colorEstado(
                            incidente!['estado'],
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _colorEstado(incidente!['estado']),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estado actual',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                incidente!['estado']
                                    .toString()
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _colorEstado(incidente!['estado']),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (incidente!['estado'] == 'en_proceso') ...[
                            const Spacer(),
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF534AB7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (incidente!['estado'] == 'en_camino' &&
                        incidente!['tecnico'] != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SeguimientoScreen(incidente: incidente!),
                          ),
                        ),
                        icon: const Icon(Icons.map),
                        label: const Text(
                          'Ver técnico en el mapa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    if (incidente!['estado'] == 'buscando_taller' ||
                        incidente!['estado'] == 'taller_asignado') ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CotizacionesScreen(
                              incidenteId: incidente!['id'],
                            ),
                          ),
                        ).then((_) => _cargar()),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text(
                          'Ver cotizaciones y talleres',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBA7517),
                          side: const BorderSide(color: Color(0xFFBA7517)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    // Información del incidente
                    _card(
                      titulo: 'Información',
                      icono: Icons.description,
                      child: Column(
                        children: [
                          _fila(
                            'Tipo de problema',
                            incidente!['tipo_problema'] ?? 'Sin clasificar',
                          ),
                          _fila(
                            'Prioridad',
                            incidente!['prioridad'] ?? 'media',
                          ),
                          _fila(
                            'Ubicación',
                            '${double.parse(incidente!['latitud'].toString()).toStringAsFixed(4)}, '
                                '${double.parse(incidente!['longitud'].toString()).toStringAsFixed(4)}',
                          ),
                          _fila('Fecha', _formatFecha(incidente!['creado_en'])),
                          if (incidente!['descripcion_texto'] != null &&
                              incidente!['descripcion_texto']
                                  .toString()
                                  .isNotEmpty)
                            _fila(
                              'Descripción',
                              incidente!['descripcion_texto'],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Taller asignado
                    if (incidente!['taller_id'] != null)
                      _card(
                        titulo: 'Taller asignado',
                        icono: Icons.store,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Color(0xFF534AB7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Taller asignado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'En camino a tu ubicación',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1D9E75),
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                    if (incidente!['taller_id'] != null)
                      const SizedBox(height: 16),

                    // Resumen IA
                    if (incidente!['resumen_ia'] != null ||
                        incidente!['clasificacion_ia'] != null)
                      _card(
                        titulo: '✦ Análisis de IA',
                        icono: Icons.auto_awesome,
                        child: Column(
                          children: [
                            if (incidente!['clasificacion_ia'] != null)
                              _fila(
                                'Clasificación',
                                incidente!['clasificacion_ia'],
                              ),
                            if (incidente!['resumen_ia'] != null)
                              _fila('Resumen', incidente!['resumen_ia']),
                          ],
                        ),
                      ),

                    if (incidente!['resumen_ia'] != null ||
                        incidente!['clasificacion_ia'] != null)
                      const SizedBox(height: 16),

                    // Historial
                    _card(
                      titulo: 'Historial de estados',
                      icono: Icons.history,
                      child: historial.isEmpty
                          ? const Text(
                              'Sin historial aún',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            )
                          : Column(
                              children: historial.asMap().entries.map((entry) {
                                final h = entry.value;
                                final esUltimo =
                                    entry.key == historial.length - 1;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF534AB7),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (!esUltimo)
                                            Container(
                                              width: 1,
                                              height: 30,
                                              color: const Color(0xFFE0DDD6),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  h['estado_anterior'] ??
                                                      'inicio',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const Text(
                                                  ' → ',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  h['estado_nuevo'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1a1a1a),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${h['actor_tipo'] ?? ''} · ${_formatFecha(h['creado_en'])}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            if (h['nota'] != null)
                                              Text(
                                                h['nota'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Color(0xFF555555),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Botón de pago
                    if (incidente!['estado'] == 'finalizado')
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PagoScreen(
                              incidenteId: incidente!['id'],
                              descripcion:
                                  incidente!['descripcion_texto'] ??
                                  'Servicio de asistencia vehicular',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.payment),
                        label: const Text(
                          'Realizar pago',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF534AB7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                    if (incidente!['estado'] == 'finalizado') ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CalificacionScreen(
                              incidenteId: incidente!['id'],
                              descripcion:
                                  incidente!['descripcion_texto'] ??
                                  'Servicio de asistencia vehicular',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.star_outline),
                        label: const Text(
                          'Calificar servicio',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBA7517),
                          side: const BorderSide(color: Color(0xFFBA7517)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card({
    required String titulo,
    required IconData icono,
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
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1a1a1a)),
            ),
          ),
        ],
      ),
    );
  }
}
