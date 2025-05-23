import 'package:flutter/material.dart';

class MenuLateral extends StatelessWidget {
  final Function(int) onItemSelected;
  final int seleccionado;

  const MenuLateral({
    Key? key,
    required this.onItemSelected,
    required this.seleccionado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'Menú Principal',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _crearItem(Icons.dashboard, 'Inicio', 0),
          _crearItem(Icons.inventory, 'Inventario', 1),
          _crearItem(Icons.point_of_sale, 'Nueva Venta', 2),
          _crearItem(Icons.history, 'Historial de Ventas', 3),
          _crearItem(Icons.bar_chart, 'Reportes', 4),
        ],
      ),
    );
  }

  Widget _crearItem(IconData icono, String texto, int indice) {
    return ListTile(
      leading: Icon(icono),
      title: Text(texto),
      selected: seleccionado == indice,
      onTap: () => onItemSelected(indice),
    );
  }
}
