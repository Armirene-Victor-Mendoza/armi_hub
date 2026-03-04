import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request) async {
    try {
      final response = await _apiClient.postJson('/integracion/customer-terceros/signature', request.toJson());

      if (response.isSuccess) {
        return CreateOrderResult(success: true, statusCode: response.statusCode, responseBodyRaw: response.bodyRaw);
      }

      return CreateOrderResult(
        success: false,
        statusCode: response.statusCode,
        responseBodyRaw: response.bodyRaw,
        errorMessage: 'El backend respondio con codigo ${response.statusCode}.',
      );
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
}
