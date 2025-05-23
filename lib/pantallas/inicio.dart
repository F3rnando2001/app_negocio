import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../servicios/venta_servicio.dart';
import '../servicios/producto_servicio.dart';
import '../modelos/venta.dart';
import '../modelos/producto.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({Key? key}) : super(key: key);

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final VentaServicio _ventaServicio = VentaServicio();
  final ProductoServicio _productoServicio = ProductoServicio();
  late Future<List<Venta>> _ventasFuture;
  late Future<List<MapEntry<int, Producto>>> _productosFuture;
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
    _productosFuture = _productoServicio.obtenerProductos();
  }

  double _ventasDelDia(List<Venta> ventas) {
    final hoy = DateTime.now();
    return ventas
        .where(
          (v) =>
              v.fecha.day == hoy.day &&
              v.fecha.month == hoy.month &&
              v.fecha.year == hoy.year,
        )
        .fold(
          0.0,
          (s, v) =>
              s +
              v.productosVendidos.fold(
                0.0,
                (ss, p) => ss + p.cantidad * p.precioUnitario,
              ),
        );
  }

  double _ventasDelMes(List<Venta> ventas) {
    final hoy = DateTime.now();
    return ventas
        .where((v) => v.fecha.month == hoy.month && v.fecha.year == hoy.year)
        .fold(
          0.0,
          (s, v) =>
              s +
              v.productosVendidos.fold(
                0.0,
                (ss, p) => ss + p.cantidad * p.precioUnitario,
              ),
        );
  }

  Map<String, double> _ventasRecientes(List<Venta> ventas) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            FutureBuilder<List<Venta>>(
              future: _ventasFuture,
              builder: (context, snapshotVentas) {
                return FutureBuilder<List<MapEntry<int, Producto>>>(
                  future: _productosFuture,
                  builder: (context, snapshotProductos) {
                    if (snapshotVentas.connectionState ==
                            ConnectionState.waiting ||
                        snapshotProductos.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshotVentas.hasError ||
                        snapshotProductos.hasError) {
                      return Center(child: Text('Error al cargar datos.'));
                    } else {
                      final ventas = snapshotVentas.data ?? [];
                      final productos = snapshotProductos.data ?? [];
                      final ventasDia = _ventasDelDia(ventas);
                      final ventasMes = _ventasDelMes(ventas);
                      final totalProductos = productos.length;
                      final ventasRecientes = _ventasRecientes(ventas);
                      final dias = ventasRecientes.keys.toList();
                      final valores = ventasRecientes.values.toList();
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _DashboardCard(
                                titulo: 'Ventas del día',
                                valor: formatoMoneda.format(ventasDia),
                                icono: Icons.today,
                                color: Colors.green,
                              ),
                              _DashboardCard(
                                titulo: 'Ventas del mes',
                                valor: formatoMoneda.format(ventasMes),
                                icono: Icons.calendar_month,
                                color: Colors.blue,
                              ),
                              _DashboardCard(
                                titulo: 'Productos',
                                valor: '$totalProductos',
                                icono: Icons.inventory,
                                color: Colors.deepPurple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ventas recientes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Últimas ventas',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ventas.length > 5 ? 5 : ventas.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final venta = ventas[ventas.length - 1 - index];
                              final total = venta.productosVendidos.fold(
                                0.0,
                                (s, p) => s + p.cantidad * p.precioUnitario,
                              );
                              return Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.deepPurple,
                                  ),
                                  title: Text(
                                    'Venta del ${DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha)}',
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
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  const _DashboardCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(titulo, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
