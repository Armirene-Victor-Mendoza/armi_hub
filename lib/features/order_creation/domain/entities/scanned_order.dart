import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/payment_method_option.dart';

class ScannedOrder {
  const ScannedOrder({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.businessId,
    required this.storeId,
    required this.totalValue,
    required this.paymentMethod,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.ocrRawText,
    required this.receiptImagePath,
    required this.requestJson,
    required this.status,
    this.ocrTotal,
    this.responseStatusCode,
    this.responseBodyRaw,
    this.errorMessage,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int businessId;
  final String storeId;
  final double totalValue;
  final int paymentMethod;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final String ocrRawText;
  final double? ocrTotal;
  final String receiptImagePath;
  final String requestJson;
  final int? responseStatusCode;
  final String? responseBodyRaw;
  final OrderSyncStatus status;
  final String? errorMessage;

  ScannedOrder copyWith({
    DateTime? updatedAt,
    int? responseStatusCode,
    String? responseBodyRaw,
    OrderSyncStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ScannedOrder(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessId: businessId,
      storeId: storeId,
      totalValue: totalValue,
      paymentMethod: paymentMethod,
      firstName: firstName,
      lastName: lastName,
      address: address,
      phone: phone,
      ocrRawText: ocrRawText,
      ocrTotal: ocrTotal,
      receiptImagePath: receiptImagePath,
      requestJson: requestJson,
      responseStatusCode: responseStatusCode ?? this.responseStatusCode,
      responseBodyRaw: responseBodyRaw ?? this.responseBodyRaw,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'business_id': businessId,
      'store_id': storeId,
      'total_value': totalValue,
      'payment_method': paymentMethod,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'phone': phone,
      'ocr_raw_text': ocrRawText,
      'ocr_total': ocrTotal,
      'receipt_image_path': receiptImagePath,
      'request_json': requestJson,
      'response_status_code': responseStatusCode,
      'response_body_raw': responseBodyRaw,
      'status': status.value,
      'error_message': errorMessage,
    };
  }

  factory ScannedOrder.fromMap(Map<String, dynamic> map) {
    return ScannedOrder(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      businessId: map['business_id'] as int,
      storeId: map['store_id'] as String,
      totalValue: _readDouble(map['total_value']),
      paymentMethod: map['payment_method'] as int,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      ocrRawText: map['ocr_raw_text'] as String? ?? '',
      ocrTotal: map['ocr_total'] == null ? null : _readDouble(map['ocr_total']),
      receiptImagePath: map['receipt_image_path'] as String? ?? '',
      requestJson: map['request_json'] as String? ?? '{}',
      responseStatusCode: map['response_status_code'] as int?,
      responseBodyRaw: map['response_body_raw'] as String?,
      status: OrderSyncStatusX.fromValue(map['status'] as String? ?? 'error'),
      errorMessage: map['error_message'] as String?,
    );
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String get statusLabel {
    switch (status) {
      case OrderSyncStatus.pending:
        return 'Pendiente';
      case OrderSyncStatus.success:
        return 'Enviada';
      case OrderSyncStatus.error:
        return 'Error';
    }
  }

  String get paymentMethodLabel {
    return '${paymentMethod.toString()} - ${PaymentMethodCatalog.nameFor(paymentMethod)}';
  }
}
