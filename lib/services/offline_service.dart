import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'incidente_service.dart';

class OfflineService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _inicializar();
    return _db!;
  }

  static Future<Database> _inicializar() async {
    final ruta = join(await getDatabasesPath(), 'emergencias_offline.db');
    return openDatabase(
      ruta,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE incidentes_offline (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehiculo_id TEXT NOT NULL,
            latitud REAL NOT NULL,
            longitud REAL NOT NULL,
            descripcion_texto TEXT,
            tipo_problema TEXT,
            imagen_path TEXT,
            audio_path TEXT,
            estado TEXT DEFAULT 'pendiente_sync',
            error_msg TEXT,
            creado_en TEXT NOT NULL,
            sincronizado_en TEXT
          )
        ''');
      },
    );
  }

  static Future<bool> hayConexion() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<int> guardarIncidenteLocal({
    required String vehiculoId,
    required double latitud,
    required double longitud,
    String? descripcionTexto,
    String? tipoProblema,
    String? imagenPath,
    String? audioPath,
  }) async {
    final database = await db;
    final id = await database.insert('incidentes_offline', {
      'vehiculo_id': vehiculoId,
      'latitud': latitud,
      'longitud': longitud,
      'descripcion_texto': descripcionTexto,
      'tipo_problema': tipoProblema,
      'imagen_path': imagenPath,
      'audio_path': audioPath,
      'estado': 'pendiente_sync',
      'creado_en': DateTime.now().toIso8601String(),
    });
    print('[Offline] Incidente guardado localmente con id: $id');
    return id;
  }

  static Future<List<Map<String, dynamic>>> getPendientes() async {
    final database = await db;
    return database.query(
      'incidentes_offline',
      where: 'estado = ?',
      whereArgs: ['pendiente_sync'],
      orderBy: 'creado_en ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getTodos() async {
    final database = await db;
    return database.query('incidentes_offline', orderBy: 'creado_en DESC');
  }

  static Future<void> marcarSincronizado(int id) async {
    final database = await db;
    await database.update(
      'incidentes_offline',
      {
        'estado': 'sincronizado',
        'sincronizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> marcarError(int id, String error) async {
    final database = await db;
    await database.update(
      'incidentes_offline',
      {'estado': 'error_sync', 'error_msg': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<SyncResult> sincronizar() async {
    if (!await hayConexion()) {
      return SyncResult(exitosos: 0, fallidos: 0, mensaje: 'Sin conexión');
    }

    final pendientes = await getPendientes();
    if (pendientes.isEmpty) {
      return SyncResult(exitosos: 0, fallidos: 0, mensaje: 'Sin pendientes');
    }

    print('[Offline] Sincronizando ${pendientes.length} incidentes...');
    int exitosos = 0;
    int fallidos = 0;

    for (final inc in pendientes) {
      try {
        final incidente = await IncidenteService.crearIncidente({
          'vehiculo_id': inc['vehiculo_id'],
          'latitud': inc['latitud'],
          'longitud': inc['longitud'],
          'descripcion_texto': inc['descripcion_texto'],
          'tipo_problema': inc['tipo_problema'],
        });

        if (incidente != null) {
          // Subir imagen si existe
          if (inc['imagen_path'] != null) {
            final img = File(inc['imagen_path']);
            if (await img.exists()) {
              await IncidenteService.subirImagen(incidente['id'], img);
            }
          }
          // Subir audio si existe
          if (inc['audio_path'] != null) {
            await IncidenteService.subirAudio(incidente['id'], inc['audio_path']);
          }

          await marcarSincronizado(inc['id'] as int);
          exitosos++;
          print('[Offline] Incidente ${inc['id']} sincronizado');
        } else {
          await marcarError(inc['id'] as int, 'Error al crear incidente');
          fallidos++;
        }
      } catch (e) {
        await marcarError(inc['id'] as int, e.toString());
        fallidos++;
        print('[Offline] Error sincronizando ${inc['id']}: $e');
      }
    }

    return SyncResult(
      exitosos: exitosos,
      fallidos: fallidos,
      mensaje: 'Sincronizados: $exitosos, Errores: $fallidos',
    );
  }

  static Future<int> contarPendientes() async {
    final pendientes = await getPendientes();
    return pendientes.length;
  }
}

class SyncResult {
  final int exitosos;
  final int fallidos;
  final String mensaje;

  SyncResult({required this.exitosos, required this.fallidos, required this.mensaje});
}