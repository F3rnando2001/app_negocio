import 'package:flutter/material.dart';
import '../modelos/producto.dart';
import '../servicios/producto_servicio.dart';
import 'package:intl/intl.dart';

class PantallaInventario extends StatefulWidget {
  const PantallaInventario({Key? key}) : super(key: key);

  @override
  State<PantallaInventario> createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  final ProductoServicio _productoServicio = ProductoServicio();
  late Future<List<MapEntry<int, Producto>>> _productosFuture;
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';
  final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

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

  void _mostrarDialogoAgregarProducto() {
    _mostrarDialogoProducto();
  }

  void _mostrarDialogoEditarProducto(int key, Producto producto) {
    _mostrarDialogoProducto(key: key, producto: producto);
  }

  void _mostrarDialogoProducto({int? key, Producto? producto}) {
    final _formKey = GlobalKey<FormState>();
    String codigo = producto?.codigo ?? '';
    String nombre = producto?.nombre ?? '';
    String categoria = producto?.categoria ?? '';
    double? precio = producto?.precio;
    int? cantidad = producto?.cantidad;
    final codigoController = TextEditingController(text: codigo);
    final nombreController = TextEditingController(text: nombre);
    final cantidadController = TextEditingController(
      text: cantidad != null ? cantidad.toString() : '',
    );
    final categoriaController = TextEditingController(text: categoria);
    final precioController = TextEditingController(
      text: precio != null ? formatoMoneda.format(precio) : '',
    );

    void actualizarPrecio(String value) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isEmpty) {
        precioController.text = '';
        return;
      }
      final valueDouble = double.parse(clean) / 100;
      final nuevoTexto = formatoMoneda.format(valueDouble);
      if (precioController.text != nuevoTexto) {
        precioController.value = TextEditingValue(
          text: nuevoTexto,
          selection: TextSelection.collapsed(offset: nuevoTexto.length),
        );
      }
    }

    precioController.addListener(() {
      final text = precioController.text;
      if (text.isEmpty) return;
      final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
      final valueDouble = double.parse(clean) / 100;
      final nuevoTexto = formatoMoneda.format(valueDouble);
      if (text != nuevoTexto) {
        precioController.value = TextEditingValue(
          text: nuevoTexto,
          selection: TextSelection.collapsed(offset: nuevoTexto.length),
        );
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(key == null ? 'Añadir producto' : 'Editar producto'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codigoController,
                    decoration: const InputDecoration(labelText: 'Código'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                    onSaved: (value) => codigo = value!,
                  ),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                    onSaved: (value) => nombre = value!,
                  ),
                  TextFormField(
                    controller: precioController,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Campo requerido';
                      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (clean.isEmpty) return 'Campo requerido';
                      return null;
                    },
                    onChanged: actualizarPrecio,
                    onSaved: (value) {
                      final clean = value!.replaceAll(RegExp(r'[^0-9]'), '');
                      precio = double.parse(clean) / 100;
                    },
                  ),
                  TextFormField(
                    controller: cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Campo requerido';
                      final n = int.tryParse(value);
                      if (n == null) return 'Debe ser un número entero';
                      return null;
                    },
                    onSaved: (value) => cantidad = int.parse(value!),
                  ),
                  TextFormField(
                    controller: categoriaController,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                    onSaved: (value) => categoria = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final nuevoProducto = Producto(
                    codigo: codigo,
                    nombre: nombre,
                    precio: precio!,
                    cantidad: cantidad!,
                    categoria: categoria,
                  );
                  if (key == null) {
                    await _productoServicio.agregarProducto(nuevoProducto);
                  } else {
                    await _productoServicio.actualizarProducto(
                      key,
                      nuevoProducto,
                    );
                  }
                  if (mounted) Navigator.of(context).pop();
                  _cargarProductos();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminarProducto(int key) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar producto'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este producto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _productoServicio.eliminarProducto(key);
                  if (mounted) Navigator.of(context).pop();
                  _cargarProductos();
                },
                child: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  List<String> _obtenerCategorias(List<MapEntry<int, Producto>> productos) {
    final categorias = productos.map((e) => e.value.categoria).toSet().toList();
    categorias.sort();
    return ['Todas', ...categorias];
  }

  List<MapEntry<int, Producto>> _filtrarProductos(
    List<MapEntry<int, Producto>> productos,
  ) {
    var filtrados = productos;
    if (_categoriaSeleccionada != 'Todas') {
      filtrados =
          filtrados
              .where((entry) => entry.value.categoria == _categoriaSeleccionada)
              .toList();
    }
    if (_busqueda.isEmpty) return filtrados;
    final query = _busqueda.toLowerCase();
    return filtrados.where((entry) {
      final p = entry.value;
      return p.nombre.toLowerCase().contains(query) ||
          p.codigo.toLowerCase().contains(query) ||
          p.categoria.toLowerCase().contains(query);
    }).toList();
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
            const SizedBox(height: 12),
            FutureBuilder<List<MapEntry<int, Producto>>>(
              future: _productosFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox();
                }
                final categorias = _obtenerCategorias(snapshot.data!);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        categorias
                            .map(
                              (cat) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: _categoriaSeleccionada == cat,
                                  onSelected: (selected) {
                                    setState(() {
                                      _categoriaSeleccionada = cat;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                  ),
                );
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
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay productos registrados.'),
                    );
                  } else {
                    final productos = _filtrarProductos(snapshot.data!);
                    if (productos.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay productos que coincidan con la búsqueda o filtro.',
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: productos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = productos[index];
                        final key = entry.key;
                        final producto = entry.value;
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        producto.nombre,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Código: ${producto.codigo} | Categoría: ${producto.categoria}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              'Stock: ${producto.cantidad}',
                                            ),
                                            backgroundColor:
                                                Colors.green.shade50,
                                            labelStyle: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(
                                              formatoMoneda.format(
                                                producto.precio,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            labelStyle: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar',
                                      onPressed:
                                          () => _mostrarDialogoEditarProducto(
                                            key,
                                            producto,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar',
                                      onPressed:
                                          () => _confirmarEliminarProducto(key),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregarProducto,
        icon: const Icon(Icons.add),
        label: const Text('Añadir producto'),
      ),
    );
  }
}
