import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';

abstract class OrdersRepository {
  Future<UploadImageResult> uploadReceiptImage({required String imagePath});

  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request);

  Future<void> saveOrderAttempt(ScannedOrder order);

  Future<void> updateOrderAttempt(ScannedOrder order);

  Future<ScannedOrder?> getOrderById(String id);

  Future<List<ScannedOrder>> getOrderHistory({String? status});
}
