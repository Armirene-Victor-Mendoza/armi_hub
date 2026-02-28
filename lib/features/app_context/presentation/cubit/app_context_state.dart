import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:equatable/equatable.dart';

class AppContextState extends Equatable {
  const AppContextState({
    this.isLoading = false,
    this.context,
    this.errorMessage,
  });

  final bool isLoading;
  final BusinessContext? context;
  final String? errorMessage;

  bool get hasContext => context != null;

  AppContextState copyWith({
    bool? isLoading,
    BusinessContext? context,
    bool clearContext = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppContextState(
      isLoading: isLoading ?? this.isLoading,
      context: clearContext ? null : (context ?? this.context),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, context, errorMessage];
}
