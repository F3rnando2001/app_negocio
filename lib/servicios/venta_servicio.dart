import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import '../modelos/venta.dart';

class VentaServicio {
  static final VentaServicio _instancia = VentaServicio._internal();
  factory VentaServicio() => _instancia;
  VentaServicio._internal();

  DatabaseFactory dbFactory = databaseFactoryWeb;
  Database? _db;
  final _store = intMapStoreFactory.store('ventas');

  Future<Database> get database async {
    if (_db == null) {
      _db = await dbFactory.openDatabase('app_negocio.db');
    }
    return _db!;
  }

  Future<void> agregarVenta(Venta venta) async {
    final db = await database;
    await _store.add(db, {
      'fecha': venta.fecha.toIso8601String(),
      'productosVendidos':
          venta.productosVendidos
              .map(
                (p) => {
                  'codigo': p.codigo,
                  'nombre': p.nombre,
                  'cantidad': p.cantidad,
                  'precioUnitario': p.precioUnitario,
                },
              )
              .toList(),
      'cantidadTotal': venta.cantidadTotal,
      'cliente': venta.cliente,
      'usuario': venta.usuario,
    });
  }

  Future<List<Venta>> obtenerVentas() async {
    final db = await database;
    final registros = await _store.find(db);
    return registros.map((snap) {
      final data = snap.value;
      return Venta(
        fecha: DateTime.parse(data['fecha'] as String),
        productosVendidos:
            (data['productosVendidos'] as List)
                .map(
                  (p) => ProductoVendido(
                    codigo: p['codigo'] as String,
                    nombre: p['nombre'] as String,
                    cantidad: p['cantidad'] as int,
                    precioUnitario: (p['precioUnitario'] as num).toDouble(),
                  ),
                )
                .toList(),
        cantidadTotal: data['cantidadTotal'] as int,
        cliente: data['cliente'] as String,
        usuario: data['usuario'] as String,
      );
    }).toList();
  }
}
