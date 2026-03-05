import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:bloc/bloc.dart';

import 'review_order_state.dart';

class ReviewOrderCubit extends Cubit<ReviewOrderState> {
  static const int _maxCreationFailuresInView = 2;

  ReviewOrderCubit({required CreateOrderFromReceiptUseCase createOrderUseCase})
    : _createOrderUseCase = createOrderUseCase,
      super(const ReviewOrderState());

  final CreateOrderFromReceiptUseCase _createOrderUseCase;

  void initialize({required ReceiptCaptureResult captureResult, required BusinessContext context}) {
    final draft = _createOrderUseCase.buildInitialDraft(captureResult: captureResult, context: context);
    emit(state.copyWith(initialDraft: draft, creationFailureCount: 0, clearActiveOrderId: true, clearError: true));
  }

  Future<void> submit(OrderDraft draft) async {
    if (state.creationFailureCount >= _maxCreationFailuresInView) {
      emit(state.copyWith(errorMessage: 'No tienes mas reintentos.'));
      return;
    }

    final validationError = draft.validationError;
    if (validationError != null) {
      emit(state.copyWith(errorMessage: validationError));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final order = await _createOrderUseCase.submitOrder(
        draft,
        existingOrderId: state.activeOrderId,
        existingCreationFailureCount: state.creationFailureCount,
      );
      if (order.status == OrderSyncStatus.success) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submittedOrder: order,
            activeOrderId: order.id,
            creationFailureCount: order.creationFailureCount,
            clearError: true,
          ),
        );
        return;
      }

      final nextFailureCount = order.creationFailureCount;
      final baseError = order.errorMessage ?? 'No se pudo crear la orden. Intenta nuevamente.';
      final canRetryOnceMore = nextFailureCount < _maxCreationFailuresInView;
      final composedError = canRetryOnceMore
          ? '$baseError Puedes reintentar una vez mas.'
          : '$baseError Ya agotaste los reintentos.';

      emit(
        state.copyWith(
          isSubmitting: false,
          activeOrderId: order.id,
          creationFailureCount: nextFailureCount,
          errorMessage: composedError,
        ),
      );
    } catch (error) {
      final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
      final message = rawMessage.contains('subir la imagen') ? 'No se pudo subir la imagen, intenta de nuevo.' : rawMessage;
      emit(state.copyWith(isSubmitting: false, errorMessage: message));
    }
  }
}
