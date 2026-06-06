import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../services/auth_service.dart';

class CotizacionesScreen extends StatefulWidget {
  final String incidenteId;
  const CotizacionesScreen({super.key, required this.incidenteId});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  List<dynamic> cotizaciones = [];
  List<dynamic> candidatos = [];
  bool cargando = true;
  int tabActual = 0;
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final headers = await _headers();

    final resCot = await http.get(
      Uri.parse('${Config.apiUrl}/cotizaciones/${widget.incidenteId}'),
      headers: headers,
    );
    final resCan = await http.get(
      Uri.parse('${Config.apiUrl}/cotizaciones/talleres-candidatos/${widget.incidenteId}'),
      headers: headers,
    );

    setState(() {
      if (resCot.statusCode == 200) cotizaciones = jsonDecode(resCot.body);
      if (resCan.statusCode == 200) candidatos = jsonDecode(resCan.body);
      cargando = false;
    });
  }

  Future<void> _responder(String cotizacionId, String accion) async {
    final headers = await _headers();
    final res = await http.patch(
      Uri.parse('${Config.apiUrl}/cotizaciones/$cotizacionId/responder?accion=$accion'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      setState(() => mensaje = accion == 'aceptar' ? '✅ Cotización aceptada' : 'Cotización rechazada');
      await _cargar();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => mensaje = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Cotizaciones y talleres',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            children: [
              _tab('Cotizaciones', 0),
              _tab('Talleres cercanos', 1),
            ],
          ),
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF534AB7)))
          : Column(
              children: [
                if (mensaje.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFF0FFF4),
                    child: Text(mensaje,
                        style: const TextStyle(color: Color(0xFF276749), fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                Expanded(
                  child: tabActual == 0
                      ? _listaCotizaciones()
                      : _listaCandidatos(),
                ),
              ],
            ),
    );
  }

  Widget _tab(String label, int index) {
    final activo = tabActual == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tabActual = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activo ? const Color(0xFF534AB7) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                color: activo ? const Color(0xFF534AB7) : Colors.grey,
              )),
        ),
      ),
    );
  }

  Widget _listaCotizaciones() {
    if (cotizaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay cotizaciones aún',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 8),
            Text('Los talleres enviarán cotizaciones en breve',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cotizaciones.length,
      itemBuilder: (_, i) {
        final c = cotizaciones[i];
        final estado = c['estado'] as String;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estado == 'aceptada'
                  ? const Color(0xFF1D9E75)
                  : estado == 'rechazada'
                      ? Colors.red.shade200
                      : const Color(0xFFE0DDD6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(c['taller_nombre'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: estado == 'aceptada'
                          ? const Color(0xFFE1F5EE)
                          : estado == 'rechazada'
                              ? const Color(0xFFFCEBEB)
                              : const Color(0xFFFFFAF0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(estado,
                        style: TextStyle(
                          color: estado == 'aceptada'
                              ? const Color(0xFF085041)
                              : estado == 'rechazada'
                                  ? const Color(0xFFA32D2D)
                                  : const Color(0xFFB7791F),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(c['descripcion'] ?? '',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoChip(Icons.attach_money, 'Bs. ${c['monto_estimado']}'),
                  const SizedBox(width: 10),
                  if (c['tiempo_estimado_horas'] != null)
                    _infoChip(Icons.access_time, '${c['tiempo_estimado_horas']} horas'),
                ],
              ),
              if (estado == 'pendiente') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _responder(c['id'], 'aceptar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('✓ Aceptar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _responder(c['id'], 'rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC53030),
                          side: const BorderSide(color: Color(0xFFC53030)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('✕ Rechazar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _listaCandidatos() {
    if (candidatos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay talleres candidatos cerca',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: candidatos.length,
      itemBuilder: (_, i) {
        final t = candidatos[i];
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
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            color: Color(0xFF534AB7),
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['nombre'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(t['telefono'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${t['distancia_km']} km',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF534AB7),
                              fontSize: 14)),
                      Text('~${t['tiempo_estimado_min']} min',
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(Icons.star, '${t['calificacion_promedio']}'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.check_circle_outline, '${t['servicios_realizados']} servicios'),
                ],
              ),
              if (t['tipos_servicio'] != null && (t['tipos_servicio'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: (t['tipos_servicio'] as List).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(s.toString(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF534AB7))),
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: const Color(0xFF888888)),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }
}