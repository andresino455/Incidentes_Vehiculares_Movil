import 'package:flutter/material.dart';
import '../../services/incidente_service.dart';
import 'detalle_incidente_screen.dart';

class MisIncidentesScreen extends StatefulWidget {
  const MisIncidentesScreen({super.key});

  @override
  State<MisIncidentesScreen> createState() => _MisIncidentesScreenState();
}

class _MisIncidentesScreenState extends State<MisIncidentesScreen> {
  List<dynamic> incidentes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final data = await IncidenteService.getMisIncidentes();
    setState(() {
      incidentes = data;
      cargando = false;
    });
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'buscando_taller':
        return const Color(0xFF185FA5);
      case 'taller_asignado':
        return const Color(0xFF534AB7);
      case 'en_camino':
        return const Color(0xFF633806);
      case 'en_atencion':
        return const Color(0xFF3B6D11);
      case 'finalizado':
        return const Color(0xFF085041);
      case 'cancelado':
        return const Color(0xFFC53030);
      default:
        return Colors.grey;
    }
  }

  Color _bgEstado(String estado) {
    switch (estado) {
      case 'buscando_taller':
        return const Color(0xFFE6F1FB);
      case 'taller_asignado':
        return const Color(0xFFEEEDFE);
      case 'en_camino':
        return const Color(0xFFFAEEDA);
      case 'en_atencion':
        return const Color(0xFFEAF3DE);
      case 'finalizado':
        return const Color(0xFFE1F5EE);
      case 'cancelado':
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  Color _colorPrioridad(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return const Color(0xFFC53030);
      case 'media':
        return const Color(0xFFB7791F);
      case 'baja':
        return const Color(0xFF276749);
      default:
        return Colors.grey;
    }
  }

  IconData _iconoTipo(String? tipo) {
    switch (tipo) {
      case 'bateria':
        return Icons.battery_alert;
      case 'llanta':
        return Icons.tire_repair;
      case 'choque':
        return Icons.car_crash;
      case 'motor':
        return Icons.settings;
      default:
        return Icons.build;
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
          'Mis incidentes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          : incidentes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.car_repair_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tenés incidentes registrados',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cuando reportes una emergencia aparecerá aquí',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              color: const Color(0xFF534AB7),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: incidentes.length,
                itemBuilder: (context, i) {
                  final inc = incidentes[i];
                  final estado = inc['estado'] ?? 'pendiente';
                  final prioridad = inc['prioridad'] ?? 'media';
                  final tipo = inc['tipo_problema'];

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalleIncidenteScreen(incidenteId: inc['id']),
                      ),
                    ).then((_) => _cargar()),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0DDD6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEDFE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _iconoTipo(tipo),
                                  color: const Color(0xFF534AB7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tipo != null
                                          ? tipo[0].toUpperCase() +
                                                tipo.substring(1)
                                          : 'Sin clasificar',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatFecha(inc['creado_en']),
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
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _bgEstado(estado),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  estado.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: _colorEstado(estado),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (inc['descripcion_texto'] != null &&
                              inc['descripcion_texto']
                                  .toString()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              inc['descripcion_texto'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Footer
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${double.parse(inc['latitud'].toString()).toStringAsFixed(4)}, '
                                '${double.parse(inc['longitud'].toString()).toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _colorPrioridad(
                                      prioridad,
                                    ).withOpacity(0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Prioridad $prioridad',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _colorPrioridad(prioridad),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (estado == 'en_proceso') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF534AB7),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Taller en camino...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF534AB7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (inc['estado'] == 'buscando_taller') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F1FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF185FA5),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Buscando taller cercano...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF185FA5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (inc['estado'] == 'taller_asignado') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF534AB7),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Taller asignado, preparando técnico...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF534AB7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (inc['estado'] == 'en_camino') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAEEDA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    color: Color(0xFF633806),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Técnico en camino a tu ubicación...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF633806),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (inc['estado'] == 'en_atencion') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3DE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.build,
                                    color: Color(0xFF3B6D11),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Técnico atendiendo tu vehículo...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3B6D11),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}
