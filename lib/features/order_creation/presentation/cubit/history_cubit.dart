import 'package:armi_hub/features/order_creation/domain/use_cases/get_order_history_use_case.dart';
import 'package:bloc/bloc.dart';

import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required GetOrderHistoryUseCase getOrderHistoryUseCase,
  }) : _getOrderHistoryUseCase = getOrderHistoryUseCase,
       super(const HistoryState());

  final GetOrderHistoryUseCase _getOrderHistoryUseCase;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await _getOrderHistoryUseCase();
      emit(state.copyWith(isLoading: false, items: items, clearError: true));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo cargar el historial: $error',
        ),
      );
    }
  }
}
