import 'package:flutter/material.dart';
import '../../services/pago_service.dart';

class PagoScreen extends StatefulWidget {
  final String incidenteId;
  final String descripcion;

  const PagoScreen({
    super.key,
    required this.incidenteId,
    required this.descripcion,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final montoCtrl = TextEditingController();
  String metodoPago = 'tarjeta';
  bool cargando = false;
  String error = '';
  String exito = '';

  double get monto => double.tryParse(montoCtrl.text) ?? 0;
  double get comision => monto * 0.10;
  double get totalTaller => monto - comision;

  final metodos = [
    {'id': 'tarjeta', 'label': 'Tarjeta', 'icono': Icons.credit_card},
    {'id': 'qr', 'label': 'QR', 'icono': Icons.qr_code},
    {'id': 'efectivo', 'label': 'Efectivo', 'icono': Icons.money},
  ];

  Future<void> _pagar() async {
    if (monto <= 0) {
      setState(() => error = 'Ingresá un monto válido');
      return;
    }
    setState(() { cargando = true; error = ''; });

    final res = await PagoService.crearPago(
      incidenteId: widget.incidenteId,
      montoTotal: monto,
      metodoPago: metodoPago,
    );

    if (!mounted) return;
    if (res != null) {
      setState(() { exito = 'Pago realizado correctamente'; cargando = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        error = 'Error al procesar el pago. El incidente puede ya tener un pago registrado.';
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
        title: const Text('Realizar pago',
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

            // Info del servicio
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
                    Icon(Icons.receipt_long, color: Color(0xFF534AB7), size: 18),
                    SizedBox(width: 8),
                    Text('Resumen del servicio',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  const Divider(height: 20),
                  Text(widget.descripcion,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Monto
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
                    Icon(Icons.attach_money, color: Color(0xFF534AB7), size: 18),
                    SizedBox(width: 8),
                    Text('Monto del servicio',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: 'Bs. ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF534AB7))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (monto > 0) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    _filaResumen('Monto total', 'Bs. ${monto.toStringAsFixed(2)}', negrita: true),
                    const SizedBox(height: 6),
                    _filaResumen('Comisión plataforma (10%)', '- Bs. ${comision.toStringAsFixed(2)}',
                        color: const Color(0xFFB7791F)),
                    const SizedBox(height: 6),
                    _filaResumen('Taller recibe', 'Bs. ${totalTaller.toStringAsFixed(2)}',
                        color: const Color(0xFF276749)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Método de pago
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
                    Icon(Icons.payment, color: Color(0xFF534AB7), size: 18),
                    SizedBox(width: 8),
                    Text('Método de pago',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  ...metodos.map((m) {
                    final seleccionado = metodoPago == m['id'];
                    return GestureDetector(
                      onTap: () => setState(() => metodoPago = m['id'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: seleccionado ? const Color(0xFFEEEDFE) : Colors.white,
                          border: Border.all(
                              color: seleccionado
                                  ? const Color(0xFF534AB7)
                                  : const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(m['icono'] as IconData,
                                color: seleccionado
                                    ? const Color(0xFF534AB7)
                                    : Colors.grey,
                                size: 22),
                            const SizedBox(width: 12),
                            Text(m['label'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: seleccionado
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: seleccionado
                                        ? const Color(0xFF534AB7)
                                        : const Color(0xFF444444))),
                            const Spacer(),
                            if (seleccionado)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF534AB7), size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
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
                    style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
              ),

            if (exito.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(exito,
                    style: const TextStyle(color: Color(0xFF276749), fontSize: 13)),
              ),

            ElevatedButton.icon(
              onPressed: cargando ? null : _pagar,
              icon: cargando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.lock),
              label: Text(
                cargando ? 'Procesando...' : 'Confirmar pago${monto > 0 ? ' · Bs. ${monto.toStringAsFixed(2)}' : ''}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filaResumen(String label, String valor, {bool negrita = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(valor,
            style: TextStyle(
                fontSize: 13,
                fontWeight: negrita ? FontWeight.w600 : FontWeight.normal,
                color: color ?? const Color(0xFF1a1a1a))),
      ],
    );
  }
}