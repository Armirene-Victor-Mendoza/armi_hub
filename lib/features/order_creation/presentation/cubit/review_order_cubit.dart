import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
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
      emit(state.copyWith(isSubmitting: false, submittedOrder: order, clearError: true));
    } catch (error) {
      final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
      final message = rawMessage.contains('subir la imagen')
          ? 'No se pudo subir la imagen, intenta de nuevo.'
          : rawMessage;
      emit(state.copyWith(isSubmitting: false, errorMessage: message));
    }
  }
}
