import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/get_order_history_use_case.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/retry_failed_order_use_case.dart';
import 'package:bloc/bloc.dart';

import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  static const int _maxCreationFailuresInView = 2;

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
    if (order.creationFailureCount >= _maxCreationFailuresInView) return;

    emit(state.copyWith(retryingOrderId: order.id, clearError: true));

    try {
      final retryResult = await _retryFailedOrderUseCase(order);
      final items = await _getOrderHistoryUseCase();

      if (retryResult.status == OrderSyncStatus.success) {
        emit(
          state.copyWith(
            items: items,
            clearError: true,
            clearRetrying: true,
          ),
        );
        return;
      }

      final exhausted = retryResult.creationFailureCount >=
          _maxCreationFailuresInView;
      emit(
        state.copyWith(
          items: items,
          clearRetrying: true,
          errorMessage: exhausted
              ? 'No se pudo crear la orden. Ya agotaste el reintento en historial para esta orden.'
              : 'No se pudo crear la orden. Puedes reintentar una vez mas.',
        ),
      );
    } catch (error) {
      final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
      final isUploadFailure = rawMessage.contains('subir la imagen');
      final message = isUploadFailure
          ? 'No se pudo subir la imagen, intenta de nuevo.'
          : 'No se pudo reintentar la orden: $rawMessage';
      emit(state.copyWith(errorMessage: message, clearRetrying: true));
    }
  }
}
