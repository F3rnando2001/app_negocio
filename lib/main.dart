import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pantallas/inicio.dart';
import 'pantallas/inventario.dart';
import 'pantallas/nueva_venta.dart';
import 'pantallas/historial_ventas.dart';
import 'pantallas/reportes.dart';
import 'widgets/menu_lateral.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Negocio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PaginaPrincipal(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: [Locale('es')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  int _indiceSeleccionado = 0;

  final List<Widget> _pantallas = const [
    PantallaInicio(),
    PantallaInventario(),
    PantallaNuevaVenta(),
    PantallaHistorialVentas(),
    PantallaReportes(),
  ];

  final List<String> _titulos = const [
    'Inicio',
    'Inventario',
    'Nueva Venta',
    'Historial de Ventas',
    'Reportes',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
      Navigator.pop(context); // Cierra el Drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titulos[_indiceSeleccionado])),
      drawer: MenuLateral(
        onItemSelected: _onItemTapped,
        seleccionado: _indiceSeleccionado,
      ),
      body: _pantallas[_indiceSeleccionado],
    );
  }
}
