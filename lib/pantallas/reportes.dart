import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../servicios/venta_servicio.dart';
import '../modelos/venta.dart';

class PantallaReportes extends StatefulWidget {
  const PantallaReportes({Key? key}) : super(key: key);

  @override
  State<PantallaReportes> createState() => _PantallaReportesState();
}

class _PantallaReportesState extends State<PantallaReportes> {
  final VentaServicio _ventaServicio = VentaServicio();
  late Future<List<Venta>> _ventasFuture;
  final formatoFecha = DateFormat('dd/MM');
  final formatoMoneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _ventasFuture = _ventaServicio.obtenerVentas();
  }

  Map<String, double> _ventasPorDia(List<Venta> ventas) {
    final Map<String, double> resumen = {};
    for (var venta in ventas) {
      final dia = formatoFecha.format(venta.fecha);
      final total = venta.productosVendidos.fold(
        0.0,
        (s, p) => s + p.cantidad * p.precioUnitario,
      );
      resumen[dia] = (resumen[dia] ?? 0) + total;
    }
    return resumen;
  }

  List<_ProductoReporte> _productosMasVendidos(List<Venta> ventas) {
    final Map<String, _ProductoReporte> resumen = {};
    for (var venta in ventas) {
      for (var p in venta.productosVendidos) {
        if (!resumen.containsKey(p.codigo)) {
          resumen[p.codigo] = _ProductoReporte(
            codigo: p.codigo,
            nombre: p.nombre,
            cantidadVendida: 0,
            montoTotal: 0.0,
          );
        }
        resumen[p.codigo]!.cantidadVendida += p.cantidad;
        resumen[p.codigo]!.montoTotal += p.cantidad * p.precioUnitario;
      }
    }
    final lista = resumen.values.toList();
    lista.sort((a, b) => b.cantidadVendida.compareTo(a.cantidadVendida));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    final resumen = _ventasPorDia(snapshot.data!);
                    final dias = resumen.keys.toList();
                    final valores = resumen.values.toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ventas por día',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: Colors.deepPurple.shade100,
                                  getTooltipItem: (
                                    group,
                                    groupIndex,
                                    rod,
                                    rodIndex,
                                  ) {
                                    return BarTooltipItem(
                                      formatoMoneda.format(rod.toY),
                                      const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 20000,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0) return const Text('0');
                                      if (value % 20000 == 0)
                                        return Text('${(value ~/ 1000)}K');
                                      return const Text('');
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < dias.length) {
                                        return Text(dias[idx]);
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 20000,
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(dias.length, (i) {
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: valores[i],
                                      color: Colors.deepPurple,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Productos más vendidos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount:
                                _productosMasVendidos(snapshot.data!).length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final producto =
                                  _productosMasVendidos(snapshot.data!)[index];
                              return Card(
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
                                  title: Text(producto.nombre),
                                  subtitle: Text(
                                    'Cantidad vendida: ${producto.cantidadVendida}',
                                  ),
                                  trailing: Text(
                                    formatoMoneda.format(producto.montoTotal),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

class _ProductoReporte {
  final String codigo;
  final String nombre;
  int cantidadVendida;
  double montoTotal;
  _ProductoReporte({
    required this.codigo,
    required this.nombre,
    required this.cantidadVendida,
    required this.montoTotal,
  });
}
