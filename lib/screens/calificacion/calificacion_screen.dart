import 'package:flutter/material.dart';
import '../../services/calificacion_service.dart';

class CalificacionScreen extends StatefulWidget {
  final String incidenteId;
  final String descripcion;

  const CalificacionScreen({
    super.key,
    required this.incidenteId,
    required this.descripcion,
  });

  @override
  State<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends State<CalificacionScreen> {
  int puntuacion = 0;
  final comentarioCtrl = TextEditingController();
  bool cargando = false;
  String error = '';
  String exito = '';

  final List<String> etiquetas = [
    '',
    'Muy malo',
    'Malo',
    'Regular',
    'Bueno',
    'Excelente',
  ];

  final List<Color> colores = [
    Colors.grey,
    const Color(0xFFC53030),
    const Color(0xFFD85A30),
    const Color(0xFFB7791F),
    const Color(0xFF1D9E75),
    const Color(0xFF276749),
  ];

  Future<void> _enviarCalificacion() async {
    if (puntuacion == 0) {
      setState(() => error = 'Seleccioná una puntuación');
      return;
    }
    setState(() { cargando = true; error = ''; });

    final res = await CalificacionService.calificar(
      incidenteId: widget.incidenteId,
      puntuacion: puntuacion,
      comentario: comentarioCtrl.text.trim().isEmpty
          ? null
          : comentarioCtrl.text.trim(),
    );

    if (!mounted) return;
    if (res != null) {
      setState(() { exito = '¡Gracias por tu calificación!'; cargando = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        error = 'Error al enviar. Es posible que ya hayas calificado este servicio.';
        cargando = false;
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
        title: const Text('Calificar servicio',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

            // Descripción del servicio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DDD6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store,
                        color: Color(0xFF534AB7), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Servicio completado',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          widget.descripcion.isNotEmpty
                              ? widget.descripcion
                              : 'Asistencia vehicular',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Estrellas
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DDD6)),
              ),
              child: Column(
                children: [
                  const Text('¿Cómo fue el servicio?',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Tocá las estrellas para calificar',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Estrellas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final estrella = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => puntuacion = estrella),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            estrella <= puntuacion
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 48,
                            color: estrella <= puntuacion
                                ? const Color(0xFFBA7517)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  // Etiqueta de puntuación
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: puntuacion > 0
                        ? Container(
                            key: ValueKey(puntuacion),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: colores[puntuacion].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: colores[puntuacion].withOpacity(0.3)),
                            ),
                            child: Text(
                              etiquetas[puntuacion],
                              style: TextStyle(
                                color: colores[puntuacion],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : const Text('Sin calificar',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Comentario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DDD6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.comment_outlined,
                        color: Color(0xFF534AB7), size: 18),
                    SizedBox(width: 8),
                    Text('Comentario (opcional)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: comentarioCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText:
                          'Contanos cómo fue tu experiencia con el taller...',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDDDDD))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF534AB7))),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
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
                    borderRadius: BorderRadius.circular(8)),
                child: Text(error,
                    style: const TextStyle(
                        color: Color(0xFFA32D2D), fontSize: 13)),
              ),

            if (exito.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF276749), size: 18),
                    const SizedBox(width: 8),
                    Text(exito,
                        style: const TextStyle(
                            color: Color(0xFF276749), fontSize: 13)),
                  ],
                ),
              ),

            ElevatedButton.icon(
              onPressed: cargando || puntuacion == 0 ? null : _enviarCalificacion,
              icon: cargando
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(
                cargando ? 'Enviando...' : 'Enviar calificación',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: puntuacion > 0
                    ? const Color(0xFF534AB7)
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}