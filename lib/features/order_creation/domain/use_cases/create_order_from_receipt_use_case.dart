import 'dart:convert';

import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:uuid/uuid.dart';

class CreateOrderFromReceiptUseCase {
  CreateOrderFromReceiptUseCase({required OrdersRepository ordersRepository}) : _ordersRepository = ordersRepository;

  final OrdersRepository _ordersRepository;
  final Uuid _uuid = const Uuid();

  OrderDraft buildInitialDraft({required ReceiptCaptureResult captureResult, required BusinessContext context}) {
    final receiptData = captureResult.receiptData;
    final detectedTotal = receiptData?.totalValue;
    final preferredUploadPath = captureResult.optimizedImagePath.isNotEmpty
        ? captureResult.optimizedImagePath
        : captureResult.imagePath;

    return OrderDraft(
      totalValue: detectedTotal ?? 0,
      paymentMethod: receiptData?.paymentMethodCode,
      firstName: receiptData?.customerFirstName ?? '',
      lastName: receiptData?.customerLastName ?? '',
      address: receiptData?.customerAddress ?? '',
      phone: receiptData?.customerPhone ?? '',
      businessId: context.businessId,
      storeId: context.storeId,
      businessName: context.businessName,
      storeName: context.storeName,
      city: context.storeCity ?? '',
      receiptImagePath: preferredUploadPath,
      ocrRawText: receiptData?.rawText ?? '',
      ocrTotal: detectedTotal,
      uploadedImageUrl: null,
    );
  }

  Future<ScannedOrder> submitOrder(OrderDraft draft, {String? existingOrderId}) async {
    final validationError = draft.validationError;
    if (validationError != null) {
      throw Exception(validationError);
    }

    final now = DateTime.now();
    final orderId = existingOrderId ?? _uuid.v4();

    final uploadResult = await _resolveUploadUrl(draft);
    if (!uploadResult.success || (uploadResult.urlImage?.trim().isEmpty ?? true)) {
      final failedAttempt = _buildUploadFailedOrder(orderId: orderId, now: now, draft: draft, uploadResult: uploadResult);

      if (existingOrderId == null) {
        await _ordersRepository.saveOrderAttempt(failedAttempt);
      } else {
        await _ordersRepository.updateOrderAttempt(failedAttempt);
      }

      throw Exception(uploadResult.errorMessage ?? 'No se pudo subir la imagen, intenta de nuevo.');
    }

    final normalizedDraft = draft.copyWith(uploadedImageUrl: uploadResult.urlImage);
    final request = normalizedDraft.toCreateOrderRequest();

    final pending = ScannedOrder(
      id: orderId,
      createdAt: now,
      updatedAt: now,
      businessId: normalizedDraft.businessId,
      storeId: normalizedDraft.storeId,
      businessName: normalizedDraft.businessName,
      storeName: normalizedDraft.storeName,
      totalValue: normalizedDraft.totalValue,
      paymentMethod: normalizedDraft.paymentMethod!,
      firstName: normalizedDraft.firstName,
      lastName: normalizedDraft.lastName,
      address: normalizedDraft.address,
      phone: normalizedDraft.phone,
      city: normalizedDraft.city,
      ocrRawText: normalizedDraft.ocrRawText,
      ocrTotal: normalizedDraft.ocrTotal,
      receiptImagePath: normalizedDraft.receiptImagePath,
      requestJson: jsonEncode(request.toJson()),
      uploadedImageUrl: normalizedDraft.uploadedImageUrl,
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

  Future<UploadImageResult> _resolveUploadUrl(OrderDraft draft) async {
    final cachedUrl = draft.uploadedImageUrl?.trim();
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      return UploadImageResult(success: true, statusCode: null, responseBodyRaw: '', urlImage: cachedUrl);
    }

    return _ordersRepository.uploadReceiptImage(imagePath: draft.receiptImagePath);
  }

  ScannedOrder _buildUploadFailedOrder({
    required String orderId,
    required DateTime now,
    required OrderDraft draft,
    required UploadImageResult uploadResult,
  }) {
    return ScannedOrder(
      id: orderId,
      createdAt: now,
      updatedAt: now,
      businessId: draft.businessId,
      storeId: draft.storeId,
      businessName: draft.businessName,
      storeName: draft.storeName,
      totalValue: draft.totalValue,
      paymentMethod: draft.paymentMethod!,
      firstName: draft.firstName,
      lastName: draft.lastName,
      address: draft.address,
      phone: draft.phone,
      city: draft.city,
      ocrRawText: draft.ocrRawText,
      ocrTotal: draft.ocrTotal,
      receiptImagePath: draft.receiptImagePath,
      requestJson: jsonEncode(<String, dynamic>{
        'total_value': draft.totalValue,
        'payment_method': draft.paymentMethod,
        'first_name': draft.firstName,
        'last_name': draft.lastName,
        'address': draft.address,
        'phone': draft.phone,
        'business_id': draft.businessId,
        'store_id': draft.storeId,
        'city': draft.city,
        'url_image': draft.uploadedImageUrl ?? '',
      }),
      uploadedImageUrl: draft.uploadedImageUrl,
      responseStatusCode: uploadResult.statusCode,
      responseBodyRaw: uploadResult.responseBodyRaw,
      status: OrderSyncStatus.error,
      errorMessage: uploadResult.errorMessage ?? 'No se pudo subir la imagen, intenta de nuevo.',
    );
  }
}
