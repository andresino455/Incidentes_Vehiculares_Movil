import 'package:flutter/material.dart';
import '../../services/vehiculo_service.dart';
import 'registro_vehiculo_screen.dart';

class MisVehiculosScreen extends StatefulWidget {
  const MisVehiculosScreen({super.key});

  @override
  State<MisVehiculosScreen> createState() => _MisVehiculosScreenState();
}

class _MisVehiculosScreenState extends State<MisVehiculosScreen> {
  List<dynamic> vehiculos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    final data = await VehiculoService.getMisVehiculos();
    setState(() { vehiculos = data; cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mis vehículos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF534AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF534AB7)),
            onPressed: () async {
              final resultado = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegistroVehiculoScreen()));
              if (resultado == true) _cargar();
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF534AB7)))
          : vehiculos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No tenés vehículos registrados',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final resultado = await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegistroVehiculoScreen()));
                          if (resultado == true) _cargar();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar vehículo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF534AB7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: vehiculos.length,
                  itemBuilder: (context, i) {
                    final v = vehiculos[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            child: const Icon(Icons.directions_car, color: Color(0xFF534AB7)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${v['marca']} ${v['modelo']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('${v['anio']} · ${v['placa']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                if (v['color'] != null && v['color'].toString().isNotEmpty)
                                  Text(v['color'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (v['tipo'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(v['tipo'],
                                  style: const TextStyle(
                                      color: Color(0xFF534AB7), fontSize: 11, fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: vehiculos.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final resultado = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegistroVehiculoScreen()));
                if (resultado == true) _cargar();
              },
              backgroundColor: const Color(0xFF534AB7),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}