import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/get_order_history_use_case.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/retry_failed_order_use_case.dart';
import 'package:bloc/bloc.dart';

import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required GetOrderHistoryUseCase getOrderHistoryUseCase,
    required RetryFailedOrderUseCase retryFailedOrderUseCase,
  }) : _getOrderHistoryUseCase = getOrderHistoryUseCase,
       _retryFailedOrderUseCase = retryFailedOrderUseCase,
       super(const HistoryState());

  final GetOrderHistoryUseCase _getOrderHistoryUseCase;
  final RetryFailedOrderUseCase _retryFailedOrderUseCase;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true, clearRetrying: true));
    try {
      final items = await _getOrderHistoryUseCase();
      emit(state.copyWith(isLoading: false, items: items, clearError: true, clearRetrying: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudo cargar el historial: $error', clearRetrying: true));
    }
  }

  Future<void> retryOrder(ScannedOrder order) async {
    if (order.status != OrderSyncStatus.error) return;

    emit(state.copyWith(retryingOrderId: order.id, clearError: true));

    try {
      await _retryFailedOrderUseCase(order);
      final items = await _getOrderHistoryUseCase();
      emit(state.copyWith(items: items, clearError: true, clearRetrying: true));
    } catch (error) {
      emit(state.copyWith(errorMessage: 'No se pudo reintentar la orden: $error', clearRetrying: true));
    }
  }
}
