import 'package:armi_hub/features/order_creation/data/datasources/image_upload_remote_data_source.dart';
import 'package:armi_hub/features/order_creation/data/datasources/orders_local_data_source.dart';
import 'package:armi_hub/features/order_creation/data/datasources/orders_remote_data_source.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_request.dart';
import 'package:armi_hub/features/order_creation/domain/entities/create_order_result.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl({
    required OrdersRemoteDataSource remote,
    required OrdersLocalDataSource local,
    required ImageUploadRemoteDataSource imageUploader,
  })
    : _remote = remote,
      _local = local,
      _imageUploader = imageUploader;

  final OrdersRemoteDataSource _remote;
  final OrdersLocalDataSource _local;
  final ImageUploadRemoteDataSource _imageUploader;

  @override
  Future<UploadImageResult> uploadReceiptImage({required String imagePath}) {
    return _imageUploader.uploadReceiptImage(imagePath: imagePath);
  }

  @override
  Future<CreateOrderResult> createSignatureOrder(CreateOrderRequest request) {
    return _remote.createSignatureOrder(request);
  }

  @override
  Future<void> saveOrderAttempt(ScannedOrder order) {
    return _local.upsertOrder(order);
  }

  @override
  Future<void> updateOrderAttempt(ScannedOrder order) {
    return _local.upsertOrder(order);
  }

  @override
  Future<ScannedOrder?> getOrderById(String id) {
    return _local.getOrderById(id);
  }

  @override
  Future<List<ScannedOrder>> getOrderHistory({String? status}) {
    return _local.getOrderHistory(status: status);
  }
}
