import 'dart:convert';

import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request) async {
    try {
      final response = await _apiClient.postJson('/integracion/customer-terceros/signature', request.toJson());
      return _mapCreateOrderResponse(response);
    } on ApiException catch (error) {
      return CreateOrderResult(success: false, statusCode: null, responseBodyRaw: '', errorMessage: error.message);
    } catch (error) {
      return CreateOrderResult(
        success: false,
        statusCode: null,
        responseBodyRaw: '',
        errorMessage: 'Error inesperado creando la orden: $error',
      );
    }
  }

  CreateOrderResult _mapCreateOrderResponse(ApiResponse response) {
    final dynamic decodedBody = _tryDecodeJson(response.bodyRaw);

    if (decodedBody is! Map<String, dynamic>) {
      return CreateOrderResult(
        success: false,
        statusCode: response.statusCode,
        responseBodyRaw: response.bodyRaw,
        errorMessage: response.isSuccess
            ? 'Respuesta invalida del backend al crear la orden.'
            : 'El backend respondio con codigo ${response.statusCode}.',
      );
    }

    final rootMessage = _asString(decodedBody['message']);
    final orderResponse = decodedBody['orderResponse'];

    if (orderResponse is! Map<String, dynamic>) {
      return CreateOrderResult(
        success: false,
        statusCode: response.statusCode,
        responseBodyRaw: response.bodyRaw,
        backendMessage: rootMessage,
        errorMessage: rootMessage ?? 'No se pudo crear la orden.',
      );
    }

    final backendStatus = _asString(orderResponse['status']);
    final backendMessage = _asString(orderResponse['message']);
    final orderResponseData = orderResponse['data'];

    bool successful = false;
    String? publicOrderId;
    String? businessOrderId;

    if (orderResponseData is Map<String, dynamic>) {
      successful = orderResponseData['successful'] == true;
      publicOrderId = _asString(orderResponseData['orderId']);
      businessOrderId = _asString(orderResponseData['businessOrderId']);
    }

    final isCreated =
        response.isSuccess &&
        backendStatus?.toUpperCase() == 'CREATED' &&
        successful &&
        (publicOrderId?.trim().isNotEmpty ?? false);

    final errorMessage = isCreated
        ? null
        : _resolveErrorMessage(
            orderResponse: orderResponse,
            rootMessage: rootMessage,
            statusCode: response.statusCode,
            isHttpSuccess: response.isSuccess,
          );

    return CreateOrderResult(
      success: isCreated,
      statusCode: response.statusCode,
      responseBodyRaw: response.bodyRaw,
      errorMessage: errorMessage,
      publicOrderId: publicOrderId,
      businessOrderId: businessOrderId,
      backendStatus: backendStatus,
      backendMessage: backendMessage,
    );
  }

  String _resolveErrorMessage({
    required Map<String, dynamic> orderResponse,
    required String? rootMessage,
    required int statusCode,
    required bool isHttpSuccess,
  }) {
    final rawError = orderResponse['error'];
    final parsedOrderError = _extractOrderResponseError(rawError);
    if (parsedOrderError != null && parsedOrderError.isNotEmpty) {
      return parsedOrderError;
    }

    final backendMessage = _asString(orderResponse['message']);
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    if (rootMessage != null && rootMessage.isNotEmpty) {
      return rootMessage;
    }

    if (!isHttpSuccess) {
      return 'El backend respondio con codigo $statusCode.';
    }

    return 'No se pudo crear la orden.';
  }

  String? _extractOrderResponseError(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final decoded = _tryDecodeJson(trimmed);
      if (decoded is Map<String, dynamic>) {
        final nestedMessage = _asString(decoded['message']);
        if (nestedMessage != null && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
      return trimmed;
    }

    if (value is Map<String, dynamic>) {
      final nestedMessage = _asString(value['message']);
      if (nestedMessage != null && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }
      return jsonEncode(value);
    }

    return value.toString();
  }

  dynamic _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }
}
