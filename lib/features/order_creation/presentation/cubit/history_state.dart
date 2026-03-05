import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:equatable/equatable.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.isLoading = false,
    this.items = const <ScannedOrder>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<ScannedOrder> items;
  final String? errorMessage;

  HistoryState copyWith({
    bool? isLoading,
    List<ScannedOrder>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, items, errorMessage];
}
