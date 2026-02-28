import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';

abstract class OrdersRepository {
  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request);

  Future<void> saveOrderAttempt(ScannedOrder order);

  Future<void> updateOrderAttempt(ScannedOrder order);

  Future<ScannedOrder?> getOrderById(String id);

  Future<List<ScannedOrder>> getOrderHistory({String? status});
}
