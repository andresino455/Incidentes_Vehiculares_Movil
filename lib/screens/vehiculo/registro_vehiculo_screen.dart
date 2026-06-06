import 'package:flutter/material.dart';
import '../../services/vehiculo_service.dart';

class RegistroVehiculoScreen extends StatefulWidget {
  const RegistroVehiculoScreen({super.key});

  @override
  State<RegistroVehiculoScreen> createState() => _RegistroVehiculoScreenState();
}

class _RegistroVehiculoScreenState extends State<RegistroVehiculoScreen> {
  final marcaCtrl = TextEditingController();
  final modeloCtrl = TextEditingController();
  final anioCtrl = TextEditingController();
  final placaCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  String? tipoSeleccionado;
  bool cargando = false;
  String error = '';

  final tipos = ['Sedán', 'SUV', 'Camioneta', 'Moto', 'Furgoneta', 'Otro'];

  Future<void> _guardar() async {
    if (marcaCtrl.text.isEmpty || modeloCtrl.text.isEmpty ||
        anioCtrl.text.isEmpty || placaCtrl.text.isEmpty) {
      setState(() => error = 'Completá los campos obligatorios');
      return;
    }
    setState(() { cargando = true; error = ''; });

    final res = await VehiculoService.crearVehiculo({
      'marca': marcaCtrl.text.trim(),
      'modelo': modeloCtrl.text.trim(),
      'anio': int.tryParse(anioCtrl.text) ?? 2020,
      'placa': placaCtrl.text.trim().toUpperCase(),
      'color': colorCtrl.text.trim(),
      'tipo': tipoSeleccionado,
    });

    if (!mounted) return;
    if (res != null) {
      Navigator.pop(context, true);
    } else {
      setState(() { error = 'Error al guardar. Verificá que la placa no esté registrada.'; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Registrar vehículo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0DDD6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Icon(Icons.directions_car, color: Color(0xFF534AB7), size: 20),
                SizedBox(width: 8),
                Text('Datos del vehículo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 20),

              _campo('Marca *', marcaCtrl, 'Toyota, Chevrolet, Hyundai...'),
              const SizedBox(height: 14),
              _campo('Modelo *', modeloCtrl, 'Corolla, Spark, Tucson...'),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _campo('Año *', anioCtrl, '2020', numero: true)),
                const SizedBox(width: 12),
                Expanded(child: _campo('Color', colorCtrl, 'Blanco, Negro...')),
              ]),
              const SizedBox(height: 14),

              _campo('Placa *', placaCtrl, 'ABC-1234'),
              const SizedBox(height: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de vehículo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tipos.map((t) {
                      final sel = tipoSeleccionado == t;
                      return GestureDetector(
                        onTap: () => setState(() => tipoSeleccionado = sel ? null : t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFEEEDFE) : Colors.white,
                            border: Border.all(
                                color: sel ? const Color(0xFF534AB7) : const Color(0xFFDDDDDD)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                color: sel ? const Color(0xFF534AB7) : const Color(0xFF555555),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              if (error.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(error,
                      style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: cargando ? null : _guardar,
                icon: cargando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(cargando ? 'Guardando...' : 'Guardar vehículo',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF534AB7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, String hint, {bool numero = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: numero ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
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
      ],
    );
  }
}