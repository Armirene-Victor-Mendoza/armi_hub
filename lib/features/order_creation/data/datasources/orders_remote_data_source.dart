import 'dart:convert';

import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';

class OrdersRemoteDataSource {
  static const String _manualCreationMessage = 'Orden Recibida, creación manual';
  static const String _socketErrorMessage =
      'Revisa tu conexion a internet e intenta de nuevo.';

  const OrdersRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request) async {
    try {
      final response = await _apiClient.postJson('/integracion/customer-terceros/signature', request.toJson());
      return _mapCreateOrderResponse(response);
    } on ApiException catch (error) {
      return CreateOrderResult(
        success: false,
        orderCreated: false,
        manualCreationRequired: false,
        statusCode: null,
        responseBodyRaw: '',
        errorMessage: _mapApiErrorMessage(error.message),
      );
    } catch (error) {
      return CreateOrderResult(
        success: false,
        orderCreated: false,
        manualCreationRequired: false,
        statusCode: null,
        responseBodyRaw: '',
        errorMessage: 'Error inesperado creando la orden: $error',
      );
    }
  }

  CreateOrderResult _mapCreateOrderResponse(ApiResponse response) {
    final dynamic decodedBody = _tryDecodeJson(response.bodyRaw);
    final bodyMap = decodedBody is Map<String, dynamic> ? decodedBody : null;
    final rootMessage = _asString(bodyMap?['message']);
    final orderResponse = bodyMap?['orderResponse'];
    final orderResponseMap = orderResponse is Map<String, dynamic> ? orderResponse : null;
    final backendStatus = _asString(orderResponseMap?['status']);
    final backendMessage = _asString(orderResponseMap?['message']);
    final orderResponseData = orderResponseMap?['data'];

    bool successful = false;
    String? publicOrderId;
    String? businessOrderId;

    if (orderResponseData is Map<String, dynamic>) {
      successful = orderResponseData['successful'] == true;
      publicOrderId = _asString(orderResponseData['orderId']);
      businessOrderId = _asString(orderResponseData['businessOrderId']);
    }

    final orderCreated =
        backendStatus?.toUpperCase() == 'CREATED' &&
        successful &&
        (publicOrderId?.trim().isNotEmpty ?? false);
    final success = response.isSuccess;
    final manualCreationRequired = success && !orderCreated;
    final userMessage = manualCreationRequired ? _manualCreationMessage : null;
    final errorMessage = success
        ? null
        : _resolveTechnicalErrorMessage(
            orderResponse: orderResponseMap,
            rootMessage: rootMessage,
            statusCode: response.statusCode,
          );

    return CreateOrderResult(
      success: success,
      orderCreated: orderCreated,
      manualCreationRequired: manualCreationRequired,
      statusCode: response.statusCode,
      responseBodyRaw: response.bodyRaw,
      errorMessage: errorMessage,
      userMessage: userMessage,
      publicOrderId: publicOrderId,
      businessOrderId: businessOrderId,
      backendStatus: backendStatus,
      backendMessage: backendMessage,
    );
  }

  String _resolveTechnicalErrorMessage({
    required Map<String, dynamic>? orderResponse,
    required String? rootMessage,
    required int statusCode,
  }) {
    if (orderResponse != null) {
      final rawError = orderResponse['error'];
      final parsedOrderError = _extractOrderResponseError(rawError);
      if (parsedOrderError != null && parsedOrderError.isNotEmpty) {
        return parsedOrderError;
      }

      final backendMessage = _asString(orderResponse['message']);
      if (backendMessage != null && backendMessage.isNotEmpty) {
        return backendMessage;
      }
    }

    if (rootMessage != null && rootMessage.isNotEmpty) {
      return rootMessage;
    }

    return 'El backend respondio con codigo $statusCode.';
  }

  String _mapApiErrorMessage(String rawMessage) {
    if (_looksLikeSocketException(rawMessage)) {
      return _socketErrorMessage;
    }
    return rawMessage;
  }

  bool _looksLikeSocketException(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('connection refused');
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
