import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../modelos/producto.dart';
import '../modelos/venta.dart';
import '../servicios/producto_servicio.dart';
import '../servicios/venta_servicio.dart';

class PantallaNuevaVenta extends StatefulWidget {
  const PantallaNuevaVenta({Key? key}) : super(key: key);

  @override
  State<PantallaNuevaVenta> createState() => _PantallaNuevaVentaState();
}

class _PantallaNuevaVentaState extends State<PantallaNuevaVenta> {
  final ProductoServicio _productoServicio = ProductoServicio();
  final VentaServicio _ventaServicio = VentaServicio();
  late Future<List<MapEntry<int, Producto>>> _productosFuture;
  String _busqueda = '';
  final formatoMoneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Carrito temporal para la venta
  final List<_ProductoCarrito> _carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() {
    setState(() {
      _productosFuture = _productoServicio.obtenerProductos();
    });
  }

  List<MapEntry<int, Producto>> _filtrarProductos(
    List<MapEntry<int, Producto>> productos,
  ) {
    if (_busqueda.isEmpty) return productos;
    final query = _busqueda.toLowerCase();
    return productos.where((entry) {
      final p = entry.value;
      return p.nombre.toLowerCase().contains(query) ||
          p.codigo.toLowerCase().contains(query) ||
          p.categoria.toLowerCase().contains(query);
    }).toList();
  }

  void _agregarAlCarrito(Producto producto) {
    setState(() {
      final index = _carrito.indexWhere(
        (p) => p.producto.codigo == producto.codigo,
      );
      if (index >= 0) {
        if (_carrito[index].cantidad < producto.cantidad) {
          _carrito[index].cantidad++;
        }
      } else {
        _carrito.add(_ProductoCarrito(producto: producto, cantidad: 1));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Producto agregado: ${producto.nombre}')),
    );
  }

  void _cambiarCantidad(_ProductoCarrito item, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.remove(item);
      } else if (nuevaCantidad <= item.producto.cantidad) {
        item.cantidad = nuevaCantidad;
      }
    });
  }

  void _eliminarDelCarrito(_ProductoCarrito item) {
    setState(() {
      _carrito.remove(item);
    });
  }

  double get _total => _carrito.fold(
    0,
    (suma, item) => suma + item.producto.precio * item.cantidad,
  );

  Future<void> _registrarVenta() async {
    if (_carrito.isEmpty) return;
    final productosVendidos =
        _carrito
            .map(
              (item) => ProductoVendido(
                codigo: item.producto.codigo,
                nombre: item.producto.nombre,
                cantidad: item.cantidad,
                precioUnitario: item.producto.precio,
              ),
            )
            .toList();
    final venta = Venta(
      fecha: DateTime.now(),
      productosVendidos: productosVendidos,
      cantidadTotal: _carrito.fold(0, (s, item) => s + item.cantidad),
      cliente: '',
      usuario: '',
    );
    await _ventaServicio.agregarVenta(venta);
    // Descontar stock
    for (final item in _carrito) {
      final nuevoProducto = Producto(
        codigo: item.producto.codigo,
        nombre: item.producto.nombre,
        precio: item.producto.precio,
        cantidad: item.producto.cantidad - item.cantidad,
        categoria: item.producto.categoria,
      );
      final productos = await _productoServicio.obtenerProductos();
      final entry = productos.firstWhere(
        (e) => e.value.codigo == item.producto.codigo,
        orElse: () => MapEntry(-1, item.producto),
      );
      if (entry.key != -1) {
        await _productoServicio.actualizarProducto(entry.key, nuevoProducto);
      }
    }
    setState(() {
      _carrito.clear();
      _cargarProductos();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Venta registrada exitosamente!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _busqueda = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<MapEntry<int, Producto>>>(
                future: _productosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay productos disponibles.'),
                    );
                  } else {
                    final productos = _filtrarProductos(snapshot.data!);
                    if (productos.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay productos que coincidan con la búsqueda.',
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: productos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final producto = productos[index].value;
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Text(
                                producto.nombre.isNotEmpty
                                    ? producto.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Chip(
                                  label: Text('Stock: ${producto.cantidad}'),
                                  backgroundColor: Colors.green.shade50,
                                  labelStyle: const TextStyle(
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    formatoMoneda.format(producto.precio),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Agregar'),
                              onPressed:
                                  producto.cantidad > 0
                                      ? () => _agregarAlCarrito(producto)
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            if (_carrito.isNotEmpty) ...[
              Text(
                'Resumen de la venta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _carrito.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _carrito[index];
                  return Card(
                    color: Colors.grey.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          item.producto.nombre.isNotEmpty
                              ? item.producto.nombre[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(item.producto.nombre),
                      subtitle: Row(
                        children: [
                          Chip(
                            label: Text('Stock: ${item.producto.cantidad}'),
                            backgroundColor: Colors.green.shade50,
                            labelStyle: const TextStyle(color: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              formatoMoneda.format(item.producto.precio),
                            ),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed:
                                () => _cambiarCantidad(item, item.cantidad - 1),
                          ),
                          Text(
                            '${item.cantidad}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed:
                                item.cantidad < item.producto.cantidad
                                    ? () => _cambiarCantidad(
                                      item,
                                      item.cantidad + 1,
                                    )
                                    : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarDelCarrito(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ${formatoMoneda.format(_total)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Registrar venta'),
                  onPressed: _registrarVenta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductoCarrito {
  final Producto producto;
  int cantidad;
  _ProductoCarrito({required this.producto, required this.cantidad});
}
