import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/repositories/orders_repository.dart';

class GetOrderHistoryUseCase {
  const GetOrderHistoryUseCase(this._ordersRepository);

  final OrdersRepository _ordersRepository;

  Future<List<ScannedOrder>> call({String? status}) {
    return _ordersRepository.getOrderHistory(status: status);
  }
}
