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
      receiptImagePath: order.receiptImagePath,
      ocrRawText: order.ocrRawText,
      ocrTotal: order.ocrTotal,
    );

    return _createOrderUseCase.submitOrder(draft, existingOrderId: order.id);
  }
}
