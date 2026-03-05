import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_status.dart';
import 'package:armi_hub/features/order_creation/domain/use_cases/create_order_from_receipt_use_case.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_capture_result.dart';
import 'package:bloc/bloc.dart';

import 'review_order_state.dart';

class ReviewOrderCubit extends Cubit<ReviewOrderState> {
  ReviewOrderCubit({required CreateOrderFromReceiptUseCase createOrderUseCase})
    : _createOrderUseCase = createOrderUseCase,
      super(const ReviewOrderState());

  final CreateOrderFromReceiptUseCase _createOrderUseCase;

  void initialize({required ReceiptCaptureResult captureResult, required BusinessContext context}) {
    final draft = _createOrderUseCase.buildInitialDraft(captureResult: captureResult, context: context);
    emit(state.copyWith(initialDraft: draft, clearError: true));
  }

  Future<void> submit(OrderDraft draft) async {
    final validationError = draft.validationError;
    if (validationError != null) {
      emit(state.copyWith(errorMessage: validationError));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final order = await _createOrderUseCase.submitOrder(draft);
      if (order.status == OrderSyncStatus.success) {
        emit(
          state.copyWith(
            isSubmitting: false,
            submittedOrder: order,
            clearError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage:
              order.errorMessage ?? 'No se pudo crear la orden. Intenta nuevamente.',
        ),
      );
    } catch (error) {
      final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
      final normalized = rawMessage.toLowerCase();
      final isSocketError =
          normalized.contains('socketexception') ||
          normalized.contains('failed host lookup') ||
          normalized.contains('network is unreachable') ||
          normalized.contains('connection refused');
      final message = isSocketError
          ? 'Revisa tu conexion a internet e intenta de nuevo.'
          : rawMessage.contains('subir la imagen')
          ? 'No se pudo subir la imagen, intenta de nuevo.'
          : rawMessage;
      emit(state.copyWith(isSubmitting: false, errorMessage: message));
    }
  }
}
