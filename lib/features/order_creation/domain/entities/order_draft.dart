import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/payment_method_option.dart';

class OrderDraft {
  const OrderDraft({
    required this.totalValue,
    required this.paymentMethod,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.businessId,
    required this.storeId,
    required this.receiptImagePath,
    required this.ocrRawText,
    this.ocrTotal,
  });

  final double totalValue;
  final int paymentMethod;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final int businessId;
  final String storeId;
  final String receiptImagePath;
  final String ocrRawText;
  final double? ocrTotal;

  bool get isValid {
    return totalValue > 0 &&
        firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        address.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        storeId.trim().isNotEmpty &&
        businessId > 0;
  }

  String? get validationError {
    if (totalValue <= 0) return 'El total debe ser mayor a 0.';
    if (firstName.trim().isEmpty) return 'El nombre es obligatorio.';
    if (lastName.trim().isEmpty) return 'El apellido es obligatorio.';
    if (address.trim().isEmpty) return 'La direccion es obligatoria.';
    if (phone.trim().isEmpty) return 'El telefono es obligatorio.';
    if (storeId.trim().isEmpty) return 'El store_id es obligatorio.';
    if (businessId <= 0) return 'El business_id debe ser mayor a 0.';
    return null;
  }

  CreateOrderRequest toCreateOrderRequest() {
    return CreateOrderRequest(
      totalValue: totalValue,
      paymentMethod: paymentMethod,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      address: address.trim(),
      phone: phone.trim(),
      businessId: businessId,
      storeId: storeId.trim(),
    );
  }

  OrderDraft copyWith({
    double? totalValue,
    int? paymentMethod,
    String? firstName,
    String? lastName,
    String? address,
    String? phone,
    int? businessId,
    String? storeId,
    String? receiptImagePath,
    String? ocrRawText,
    double? ocrTotal,
    bool clearOcrTotal = false,
  }) {
    return OrderDraft(
      totalValue: totalValue ?? this.totalValue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      businessId: businessId ?? this.businessId,
      storeId: storeId ?? this.storeId,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrTotal: clearOcrTotal ? null : (ocrTotal ?? this.ocrTotal),
    );
  }

  static OrderDraft empty({required int businessId, required String storeId}) {
    return OrderDraft(
      totalValue: 0,
      paymentMethod: PaymentMethodCatalog.defaultCode,
      firstName: '',
      lastName: '',
      address: '',
      phone: '',
      businessId: businessId,
      storeId: storeId,
      receiptImagePath: '',
      ocrRawText: '',
    );
  }
}
