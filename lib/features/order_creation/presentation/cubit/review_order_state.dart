import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:equatable/equatable.dart';

class ReviewOrderState extends Equatable {
  const ReviewOrderState({
    this.initialDraft,
    this.isSubmitting = false,
    this.submittedOrder,
    this.errorMessage,
  });

  final OrderDraft? initialDraft;
  final bool isSubmitting;
  final ScannedOrder? submittedOrder;
  final String? errorMessage;

  ReviewOrderState copyWith({
    OrderDraft? initialDraft,
    bool? isSubmitting,
    ScannedOrder? submittedOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReviewOrderState(
      initialDraft: initialDraft ?? this.initialDraft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedOrder: submittedOrder ?? this.submittedOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    initialDraft,
    isSubmitting,
    submittedOrder,
    errorMessage,
  ];
}
