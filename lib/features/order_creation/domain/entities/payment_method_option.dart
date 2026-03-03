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
  ];

  static String nameFor(int code) {
    for (final option in options) {
      if (option.code == code) return option.name;
    }
    return 'Desconocido';
  }
}
