import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/app_context/domain/repositories/app_context_repository.dart';
import 'package:bloc/bloc.dart';

import 'app_context_state.dart';

class AppContextCubit extends Cubit<AppContextState> {
  AppContextCubit({required AppContextRepository repository})
    : _repository = repository,
      super(const AppContextState());

  final AppContextRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final context = await _repository.getBusinessContext();
      emit(state.copyWith(isLoading: false, context: context, clearError: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudo cargar el contexto: $error'));
    }
  }

  Future<void> save(BusinessContext context) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.saveBusinessContext(context);
      emit(state.copyWith(isLoading: false, context: context, clearError: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudo guardar el contexto: $error'));
    }
  }

  Future<void> clear() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.clearBusinessContext();
      emit(state.copyWith(isLoading: false, clearContext: true, clearError: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudo limpiar el contexto: $error'));
    }
  }
}
