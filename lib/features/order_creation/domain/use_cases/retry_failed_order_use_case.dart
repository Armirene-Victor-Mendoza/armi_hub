import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';

class RetryFailedOrderUseCase {
  const RetryFailedOrderUseCase(this._createOrderUseCase);

  final CreateOrderFromReceiptUseCase _createOrderUseCase;

  Future<ScannedOrder> call(ScannedOrder order) {
    final draft = OrderDraft(
      totalValue: order.totalValue,
      paymentMethod: order.paymentMethod,
      firstName: order.firstName,
      lastName: order.lastName,
      address: order.address,
      phone: order.phone,
      businessId: order.businessId,
      storeId: order.storeId,
      businessName: order.businessName,
      storeName: order.storeName,
      city: order.city,
      receiptImagePath: order.receiptImagePath,
      ocrRawText: order.ocrRawText,
      ocrTotal: order.ocrTotal,
      uploadedImageUrl: order.uploadedImageUrl,
    );

    return _createOrderUseCase.submitOrder(draft, existingOrderId: order.id);
  }
}
