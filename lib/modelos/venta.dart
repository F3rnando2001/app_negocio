class ProductoVendido {
  String codigo;
  String nombre;
  int cantidad;
  double precioUnitario;

  ProductoVendido({
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });
}

class Venta {
  DateTime fecha;
  List<ProductoVendido> productosVendidos;
  int cantidadTotal;
  String cliente;
  String usuario;

  Venta({
    required this.fecha,
    required this.productosVendidos,
    required this.cantidadTotal,
    required this.cliente,
    required this.usuario,
  });
}
