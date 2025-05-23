import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import '../modelos/producto.dart';

class ProductoServicio {
  static final ProductoServicio _instancia = ProductoServicio._internal();
  factory ProductoServicio() => _instancia;
  ProductoServicio._internal();

  DatabaseFactory dbFactory = databaseFactoryWeb;
  Database? _db;
  final _store = intMapStoreFactory.store('productos');

  Future<Database> get database async {
    if (_db == null) {
      _db = await dbFactory.openDatabase('app_negocio.db');
    }
    return _db!;
  }

  Future<void> agregarProducto(Producto producto) async {
    final db = await database;
    await _store.add(db, {
      'codigo': producto.codigo,
      'nombre': producto.nombre,
      'precio': producto.precio,
      'cantidad': producto.cantidad,
      'categoria': producto.categoria,
    });
  }

  Future<List<RecordSnapshot<int, Map<String, Object?>>>>
  obtenerRegistros() async {
    final db = await database;
    return await _store.find(db);
  }

  Future<List<MapEntry<int, Producto>>> obtenerProductos() async {
    final registros = await obtenerRegistros();
    return registros.map((snap) {
      final data = snap.value;
      return MapEntry(
        snap.key,
        Producto(
          codigo: data['codigo'] as String,
          nombre: data['nombre'] as String,
          precio: (data['precio'] as num).toDouble(),
          cantidad: data['cantidad'] as int,
          categoria: data['categoria'] as String,
        ),
      );
    }).toList();
  }

  Future<void> actualizarProducto(int key, Producto producto) async {
    final db = await database;
    await _store.record(key).update(db, {
      'codigo': producto.codigo,
      'nombre': producto.nombre,
      'precio': producto.precio,
      'cantidad': producto.cantidad,
      'categoria': producto.categoria,
    });
  }

  Future<void> eliminarProducto(int key) async {
    final db = await database;
    await _store.record(key).delete(db);
  }
}
