import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/venta_servicio.dart';
import '../modelos/venta.dart';

class PantallaHistorialVentas extends StatefulWidget {
  const PantallaHistorialVentas({Key? key}) : super(key: key);

  @override
  State<PantallaHistorialVentas> createState() =>
      _PantallaHistorialVentasState();
}

class _PantallaHistorialVentasState extends State<PantallaHistorialVentas> {
  final VentaServicio _ventaServicio = VentaServicio();
  late Future<List<Venta>> _ventasFuture;
  final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
  final formatoMoneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  void _cargarVentas() {
    setState(() {
      _ventasFuture = _ventaServicio.obtenerVentas();
    });
  }

  void _mostrarDetalleVenta(Venta venta) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalle de la venta'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${formatoFecha.format(venta.fecha)}'),
                const SizedBox(height: 8),
                Text(
                  'Productos vendidos:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...venta.productosVendidos.map(
                  (p) => ListTile(
                    dense: true,
                    title: Text(p.nombre),
                    subtitle: Text(
                      'Cantidad: ${p.cantidad} x ${formatoMoneda.format(p.precioUnitario)}',
                    ),
                    trailing: Text(
                      formatoMoneda.format(p.cantidad * p.precioUnitario),
                    ),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${formatoMoneda.format(venta.productosVendidos.fold(0.0, (s, p) => s + p.cantidad * p.precioUnitario))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  List<Venta> _filtrarPorFecha(List<Venta> ventas) {
    if (_fechaInicio == null && _fechaFin == null) return ventas;
    return ventas.where((venta) {
      final fecha = venta.fecha;
      if (_fechaInicio != null && fecha.isBefore(_fechaInicio!)) return false;
      if (_fechaFin != null && fecha.isAfter(_fechaFin!)) return false;
      return true;
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaInicio == null
                          ? 'Fecha inicio'
                          : formatoFecha.format(_fechaInicio!),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaInicio = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fechaFin == null
                          ? 'Fecha fin'
                          : formatoFecha.format(_fechaFin!),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaFin = picked;
                        });
                      }
                    },
                  ),
                ),
                if (_fechaInicio != null || _fechaFin != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpiar filtro',
                    onPressed: () {
                      setState(() {
                        _fechaInicio = null;
                        _fechaFin = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Venta>>(
                future: _ventasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay ventas registradas.'),
                    );
                  } else {
                    final ventas = _filtrarPorFecha(snapshot.data!);
                    if (ventas.isEmpty) {
                      return const Center(
                        child: Text('No hay ventas en el rango seleccionado.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: ventas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final venta = ventas[index];
                        final total = venta.productosVendidos.fold(
                          0.0,
                          (s, p) => s + p.cantidad * p.precioUnitario,
                        );
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              'Venta del ${formatoFecha.format(venta.fecha)}',
                            ),
                            subtitle: Text(
                              'Productos: ${venta.productosVendidos.length}',
                            ),
                            trailing: Text(
                              formatoMoneda.format(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => _mostrarDetalleVenta(venta),
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
    );
  }
}
