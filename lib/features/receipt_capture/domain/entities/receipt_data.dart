class ReceiptData {
  final String rawText;
  final double? totalValue;
  final int? paymentMethodCode; // 1: Efectivo, 2: Datafono, 3: Transaccion en linea
  final String? paymentMethodLabelRaw;
  final String? customerNameRaw;
  final String? customerFirstName;
  final String? customerLastName;
  final String? customerAddress;
  final String? customerPhone;
  final DateTime? receiptDateTime;
  final String? orderCentralId;
  final String? platformOrderId;
  final Map<String, String> extra;

  const ReceiptData({
    required this.rawText,
    this.totalValue,
    this.paymentMethodCode,
    this.paymentMethodLabelRaw,
    this.customerNameRaw,
    this.customerFirstName,
    this.customerLastName,
    this.customerAddress,
    this.customerPhone,
    this.receiptDateTime,
    this.orderCentralId,
    this.platformOrderId,
    this.extra = const {},
  });

  bool get hasMinimumFields {
    return totalValue != null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rawText': rawText,
      'totalValue': totalValue,
      'paymentMethodCode': paymentMethodCode,
      'paymentMethodLabelRaw': paymentMethodLabelRaw,
      'customerNameRaw': customerNameRaw,
      'customerFirstName': customerFirstName,
      'customerLastName': customerLastName,
      'customerAddress': customerAddress,
      'customerPhone': customerPhone,
      'receiptDateTime': receiptDateTime?.toIso8601String(),
      'orderCentralId': orderCentralId,
      'platformOrderId': platformOrderId,
      'extra': extra,
    };
  }

  @override
  String toString() {
    return 'ReceiptData('
        'totalValue: $totalValue, paymentMethodCode: $paymentMethodCode, '
        'paymentMethodLabelRaw: $paymentMethodLabelRaw, customerNameRaw: $customerNameRaw, '
        'customerFirstName: $customerFirstName, customerLastName: $customerLastName, '
        'customerAddress: $customerAddress, customerPhone: $customerPhone, '
        'receiptDateTime: $receiptDateTime, orderCentralId: $orderCentralId, '
        'platformOrderId: $platformOrderId'
        ')';
  }
}
