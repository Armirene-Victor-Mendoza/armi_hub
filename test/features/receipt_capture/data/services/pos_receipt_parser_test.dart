import 'package:armi_hub/features/receipt_capture/data/services/pos_receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PosReceiptParser', () {
    final parser = PosReceiptParser();

    test('parsea tarjeta debito con total, cliente, direccion, celular e ids', () {
      const raw = '''
FECHA : 26/02/2026
HORA DE LLEGADA DOMICILIO 13:12:09
TOTAL : \$41,900
TARJETA DEBITO : \$41,900
CLIENTE: LILIANA CARRERA
NIT : 66908429-0
DIRECCI: CALLE 147 # 19 - 79, APARTAMENTO
TORRE B EDF IOS, BARRI CEDRITOS SUBZONA:0
TEL-EXT: -
CEL: 3187740893
PEDIDO CENTRAL : 20363125
PEDIDO PLATAFORMA # : 9665575
''';

      final result = parser.parse(raw);
      expect(result.success, isTrue);
      expect(result.receiptData, isNotNull);

      final data = result.receiptData!;
      expect(data.totalValue, 41900);
      expect(data.paymentMethodCode, 2);
      expect(data.paymentMethodLabelRaw, 'TARJETA DEBITO');
      expect(data.customerNameRaw, 'LILIANA CARRERA');
      expect(data.customerFirstName, 'LILIANA');
      expect(data.customerLastName, 'CARRERA');
      expect(data.customerAddress, contains('CALLE 147'));
      expect(data.customerAddress, contains('SUBZONA:0'));
      expect(data.customerAddress, isNot(contains('CEL:')));
      expect(data.customerPhone, '3187740893');
      expect(data.orderCentralId, '20363125');
      expect(data.platformOrderId, '9665575');
      expect(data.receiptDateTime, isNotNull);
    });

    test('mapea EFECTIVO a payment_method 1', () {
      const raw = '''
FECHA : 26/02/2026
TOTAL : \$64,800
EFECTIVO : \$64,800
CLIENTE: GLORIA DUQUE
DIRECCI: CARRERA 16 # 14 - 61
APARTAMENTO 603
CEL: 3102067486
''';

      final result = parser.parse(raw);
      expect(result.success, isTrue);
      expect(result.receiptData?.paymentMethodCode, 1);
      expect(result.receiptData?.customerFirstName, 'GLORIA');
      expect(result.receiptData?.customerLastName, 'DUQUE');
    });

    test('si cliente tiene un solo token deja lastName vacio', () {
      const raw = '''
TOTAL : \$81,800
TARJETA DEBITO : \$81,800
CLIENTE: MARIANA
DIRECCI: CALLE 147 #14-69
CEL: 3008760104
''';

      final result = parser.parse(raw);
      expect(result.success, isTrue);
      expect(result.receiptData?.customerFirstName, 'MARIANA');
      expect(result.receiptData?.customerLastName, '');
    });

    test('direccion multilinea se une y se corta al llegar a CEL', () {
      const raw = '''
TOTAL : \$70,900
TARJETA DEBITO : \$70,900
CLIENTE: ESTEBAN CAMARGO
DIRECCI: CRA. 13 #152-80, BOGOTA, COLOMBIA
APTO 215 SUBZONA:01
CEL: 3112295481
PEDIDO CENTRAL : 20363149
''';

      final result = parser.parse(raw);
      final address = result.receiptData?.customerAddress ?? '';

      expect(result.success, isTrue);
      expect(address, contains('CRA. 13 #152-80'));
      expect(address, contains('APTO 215'));
      expect(address, isNot(contains('CEL:')));
      expect(address, isNot(contains('PEDIDO CENTRAL')));
    });

    test('si metodo de pago no es reconocido queda null', () {
      const raw = '''
TOTAL : \$15,000
PAGO MIXTO : \$15,000
CLIENTE: JUAN PEREZ
DIRECCI: CALLE 10 #20-30
CEL: 3001234567
''';

      final result = parser.parse(raw);

      expect(result.success, isTrue);
      expect(result.receiptData?.paymentMethodCode, isNull);
    });

    test('tolera OCR ruidoso en etiquetas CLIENTE/DIRECCI/TOTAL', () {
      const raw = '''
FECHA : 26/02/2026
TOTAI : \$70,900
TARJETA DEBITO : \$70,900
CLIENIE: ESTEBAN CAMARGO
DIRECCI: CRA. 13 #152-80, BOGOTA
CEL.: 3112295481
''';

      final result = parser.parse(raw);
      final data = result.receiptData;

      expect(result.success, isTrue);
      expect(data, isNotNull);
      expect(data?.totalValue, 70900);
      expect(data?.customerFirstName, 'ESTEBAN');
      expect(data?.customerLastName, 'CAMARGO');
      expect(data?.customerAddress, contains('CRA. 13 #152-80'));
      expect(data?.customerPhone, '3112295481');
    });

    test('detecta total con etiqueta de pago ruidosa TARJETA`DEBITO', () {
      const raw = '''
FECHA : 26/02/2026
TOTAL :
TARJETA`DEBITO        \$70,900
DEVOLVER : \$0
CLIENTE: ESTEBAN CAMARGO
DIRECCI: CRA. 13 #152-80, BOGOTA
CEL: 3112295481
''';

      final result = parser.parse(raw);
      final data = result.receiptData;

      expect(result.success, isTrue);
      expect(data, isNotNull);
      expect(data?.totalValue, 70900);
      expect(data?.paymentMethodCode, 2);
      expect(data?.paymentMethodLabelRaw, 'TARJETA DEBITO');
    });

    test('fallback: toma primer valor a la derecha del primer "\$"', () {
      const raw = '''
FECHA : 26/02/2026
LINEA OCR RARA SIN ETIQUETA  \$70,900
OTRA LINEA \$70,900
DEVOLVER : \$0
CLIENTE: ESTEBAN CAMARGO
DIRECCI: CRA. 13 #152-80, BOGOTA
CEL: 3112295481
''';

      final result = parser.parse(raw);
      final data = result.receiptData;

      expect(result.success, isTrue);
      expect(data, isNotNull);
      expect(data?.totalValue, 70900);
    });

    test('detecta total cuando OCR confunde "\$" por "S"', () {
      const raw = '''
FECHA : 26/02/2026
TOTAL : S70,900
TARJETA DEBITO : S70,900
CLIENTE: ESTEBAN CAMARGO
DIRECCI: CRA. 13 #152-80, BOGOTA
CEL: 3112295481
''';

      final result = parser.parse(raw);
      final data = result.receiptData;

      expect(result.success, isTrue);
      expect(data, isNotNull);
      expect(data?.totalValue, 70900);
      expect(data?.paymentMethodCode, 2);
    });

    test('detecta total cuando OCR confunde "\$" por "s" minuscula', () {
      const raw = '''
FECHA : 26/02/2026
TOTAL : s70,900
CLIENTE: ESTEBAN CAMARGO
DIRECCI: CRA. 13 #152-80, BOGOTA
CEL: 3112295481
''';

      final result = parser.parse(raw);
      final data = result.receiptData;

      expect(result.success, isTrue);
      expect(data, isNotNull);
      expect(data?.totalValue, 70900);
    });
  });
}
