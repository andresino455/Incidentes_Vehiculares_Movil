import 'package:flutter/material.dart';
import '../../services/offline_service.dart';

class IncidentesOfflineScreen extends StatefulWidget {
  const IncidentesOfflineScreen({super.key});

  @override
  State<IncidentesOfflineScreen> createState() => _IncidentesOfflineScreenState();
}

class _IncidentesOfflineScreenState extends State<IncidentesOfflineScreen> {
  List<Map<String, dynamic>> incidentes = [];
  bool cargando = true;
  bool sincronizando = false;
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final data = await OfflineService.getTodos();
    setState(() { incidentes = data; cargando = false; });
  }

  Future<void> _sincronizar() async {
    setState(() { sincronizando = true; mensaje = ''; });
    final result = await OfflineService.sincronizar();
    setState(() {
      sincronizando = false;
      mensaje = result.mensaje;
    });
    await _cargar();
    if (result.exitosos > 0) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => mensaje = '');
      });
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente_sync': return const Color(0xFFB7791F);
      case 'sincronizado': return const Color(0xFF276749);
      case 'error_sync': return const Color(0xFFC53030);
      default: return Colors.grey;
    }
  }

  Color _bgEstado(String estado) {
    switch (estado) {
      case 'pendiente_sync': return const Color(0xFFFFFAF0);
      case 'sincronizado': return const Color(0xFFF0FFF4);
      case 'error_sync': return const Color(0xFFFFF0F0);
      default: return const Color(0xFFF0F0F0);
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'pendiente_sync': return '⏳ Pendiente de sincronización';
      case 'sincronizado': return '✅ Sincronizado';
      case 'error_sync': return '❌ Error al sincronizar';
      default: return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = incidentes.where((i) => i['estado'] == 'pendiente_sync').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Emergencias guardadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      body: Column(
        children: [

          // Banner de pendientes
          if (pendientes > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFFAF0),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Color(0xFFB7791F), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$pendientes emergencia${pendientes > 1 ? 's' : ''} pendiente${pendientes > 1 ? 's' : ''} de sincronización',
                      style: const TextStyle(color: Color(0xFFB7791F), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: sincronizando ? null : _sincronizar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF534AB7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: sincronizando
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Sincronizar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Mensaje resultado
          if (mensaje.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF0FFF4),
              child: Text(mensaje,
                  style: const TextStyle(color: Color(0xFF276749), fontSize: 13),
                  textAlign: TextAlign.center),
            ),

          // Lista
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF534AB7)))
                : incidentes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_done, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay emergencias guardadas localmente',
                                style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: incidentes.length,
                        itemBuilder: (_, i) {
                          final inc = incidentes[i];
                          final estado = inc['estado'] as String;
                          return Container(
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inc['tipo_problema'] ?? 'Sin clasificar',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _bgEstado(estado),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _labelEstado(estado),
                                        style: TextStyle(color: _colorEstado(estado), fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                if (inc['descripcion_texto'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(inc['descripcion_texto'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(inc['latitud'] as double).toStringAsFixed(4)}, ${(inc['longitud'] as double).toStringAsFixed(4)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatFecha(inc['creado_en']),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                if (inc['error_msg'] != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCEBEB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(inc['error_msg'],
                                        style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 11)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return fecha; }
  }
}