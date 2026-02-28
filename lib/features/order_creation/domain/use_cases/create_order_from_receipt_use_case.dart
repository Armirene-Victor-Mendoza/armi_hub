import 'dart:convert';

import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/payment_method_option.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:uuid/uuid.dart';

class CreateOrderFromReceiptUseCase {
  CreateOrderFromReceiptUseCase({required OrdersRepository ordersRepository}) : _ordersRepository = ordersRepository;

  final OrdersRepository _ordersRepository;
  final Uuid _uuid = const Uuid();

  OrderDraft buildInitialDraft({required ReceiptCaptureResult captureResult, required BusinessContext context}) {
    final receiptData = captureResult.receiptData;
    final detectedTotal = receiptData?.total ?? receiptData?.monto;

    return OrderDraft(
      totalValue: detectedTotal ?? 0,
      paymentMethod: PaymentMethodCatalog.defaultCode,
      firstName: '',
      lastName: '',
      address: '',
      phone: '',
      businessId: context.businessId,
      storeId: context.storeId,
      receiptImagePath: captureResult.imagePath,
      ocrRawText: receiptData?.rawText ?? '',
      ocrTotal: detectedTotal,
    );
  }

  Future<ScannedOrder> submitOrder(OrderDraft draft, {String? existingOrderId}) async {
    final validationError = draft.validationError;
    if (validationError != null) {
      throw Exception(validationError);
    }

    final now = DateTime.now();
    final request = draft.toCreateOrderRequest();

    final pending = ScannedOrder(
      id: existingOrderId ?? _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      businessId: draft.businessId,
      storeId: draft.storeId,
      totalValue: draft.totalValue,
      paymentMethod: draft.paymentMethod,
      firstName: draft.firstName,
      lastName: draft.lastName,
      address: draft.address,
      phone: draft.phone,
      ocrRawText: draft.ocrRawText,
      ocrTotal: draft.ocrTotal,
      receiptImagePath: draft.receiptImagePath,
      requestJson: jsonEncode(request.toJson()),
      status: OrderSyncStatus.pending,
    );

    if (existingOrderId == null) {
      await _ordersRepository.saveOrderAttempt(pending);
    } else {
      await _ordersRepository.updateOrderAttempt(pending);
    }

    final result = await _ordersRepository.createSignatureOrder(request);

    final finalized = pending.copyWith(
      updatedAt: DateTime.now(),
      responseStatusCode: result.statusCode,
      responseBodyRaw: result.responseBodyRaw,
      status: result.success ? OrderSyncStatus.success : OrderSyncStatus.error,
      errorMessage: result.errorMessage,
      clearErrorMessage: result.success,
    );

    await _ordersRepository.updateOrderAttempt(finalized);

    return finalized;
  }
}
