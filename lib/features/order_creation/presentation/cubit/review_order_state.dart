import 'package:armi_hub/features/order_creation/domain/entities/order_draft.dart';
import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:equatable/equatable.dart';

class ReviewOrderState extends Equatable {
  const ReviewOrderState({
    this.initialDraft,
    this.isSubmitting = false,
    this.submittedOrder,
    this.activeOrderId,
    this.errorMessage,
    this.creationFailureCount = 0,
  });

  final OrderDraft? initialDraft;
  final bool isSubmitting;
  final ScannedOrder? submittedOrder;
  final String? activeOrderId;
  final String? errorMessage;
  final int creationFailureCount;

  ReviewOrderState copyWith({
    OrderDraft? initialDraft,
    bool? isSubmitting,
    ScannedOrder? submittedOrder,
    String? activeOrderId,
    bool clearActiveOrderId = false,
    String? errorMessage,
    int? creationFailureCount,
    bool clearError = false,
  }) {
    return ReviewOrderState(
      initialDraft: initialDraft ?? this.initialDraft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedOrder: submittedOrder ?? this.submittedOrder,
      activeOrderId: clearActiveOrderId
          ? null
          : (activeOrderId ?? this.activeOrderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      creationFailureCount: creationFailureCount ?? this.creationFailureCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    initialDraft,
    isSubmitting,
    submittedOrder,
    activeOrderId,
    errorMessage,
    creationFailureCount,
  ];
}
