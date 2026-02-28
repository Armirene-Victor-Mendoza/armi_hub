class PaymentMethodOption {
  const PaymentMethodOption({required this.code, required this.name});

  final int code;
  final String name;
}

class PaymentMethodCatalog {
  static const int defaultCode = 2;

  static const List<PaymentMethodOption> options = <PaymentMethodOption>[
    PaymentMethodOption(code: 1, name: 'Efectivo'),
    PaymentMethodOption(code: 2, name: 'Datafono'),
    PaymentMethodOption(code: 3, name: 'Transaccion en linea'),
    PaymentMethodOption(code: 5, name: 'Bancamiga'),
    PaymentMethodOption(code: 6, name: 'Transaccion en linea'),
    PaymentMethodOption(code: 7, name: 'Pago movil'),
    PaymentMethodOption(code: 8, name: 'Debito inmediato'),
    PaymentMethodOption(code: 31, name: 'Aseguradoras'),
    PaymentMethodOption(code: 32, name: 'Aseguradoras'),
    PaymentMethodOption(code: 33, name: 'Aseguradoras'),
    PaymentMethodOption(code: 34, name: 'Aseguradoras'),
    PaymentMethodOption(code: 35, name: 'Aseguradoras'),
    PaymentMethodOption(code: 36, name: 'Aseguradoras'),
    PaymentMethodOption(code: 37, name: 'Aseguradoras'),
    PaymentMethodOption(code: 38, name: 'Aseguradoras'),
    PaymentMethodOption(code: 39, name: 'Aseguradoras'),
    PaymentMethodOption(code: 100, name: 'Otro'),
  ];

  static String nameFor(int code) {
    for (final option in options) {
      if (option.code == code) return option.name;
    }
    return 'Desconocido';
  }
}
