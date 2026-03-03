import 'dart:io';

import 'package:armi_hub/core/media_picker/domain/media_picker_repository.dart';
import 'package:armi_hub/features/receipt_capture/domain/domain.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

part 'photo_evidence_state.dart';

class PhotoEvidenceCubit extends Cubit<PhotoEvidenceState> {
  final TakePhotoEvidence _captureUseCase;
  final MediaPickerRepository _mediaRepository;

  // Configuración inmutable
  final ReceiptCaptureConfig _config;

  // Lazy loading state
  TakePhotoEvidence? _lazyUseCase;
  bool _isInitialized = false;

  PhotoEvidenceCubit({
    required ReceiptCaptureConfig config,
    required TakePhotoEvidence captureUseCase,
    required MediaPickerRepository mediaRepository,
  }) : _config = config,
       _captureUseCase = captureUseCase,
       _mediaRepository = mediaRepository,
       super(const PhotoEvidenceInitial());

  /// Captura una nueva foto con lazy loading inteligente de ML Kit
  Future<void> capturePhoto() async {
    List<ReceiptCaptureResult> existingResults = [];
    if (state is PhotoEvidenceSuccess) {
      existingResults = (state as PhotoEvidenceSuccess).captureResults;
    }

    emit(const PhotoEvidenceCapturing());

    try {
      final useCase = await _getOrCreateUseCase();

      final result = await useCase.capturePhoto(imageQuality: 100);

      if (result.success && result.hasImages) {
        final allResults = [...existingResults, result];

        // Haptic feedback para éxito
        HapticFeedback.lightImpact();

        emit(
          PhotoEvidenceSuccess(
            captureResults: allResults,
            currentPhotoIndex: allResults.length - 1, // Mostrar la nueva foto
          ),
        );
      } else {
        emit(PhotoEvidenceError(message: result.error ?? 'Error desconocido capturando foto', captureResults: existingResults));
      }
    } catch (e) {
      emit(PhotoEvidenceError(message: 'Error capturando foto: $e', captureResults: existingResults));
    }
  }

  /// Elimina una foto por índice
  void removePhoto(int index) {
    if (state is! PhotoEvidenceSuccess) return;

    final currentState = state as PhotoEvidenceSuccess;
    if (index < 0 || index >= currentState.captureResults.length) return;

    final newResults = List<ReceiptCaptureResult>.from(currentState.captureResults);
    newResults.removeAt(index);

    if (newResults.isEmpty) {
      // Si no quedan fotos, volver al estado inicial
      emit(const PhotoEvidenceInitial());
    } else {
      // Ajustar el índice actual si es necesario
      int newCurrentIndex = currentState.currentPhotoIndex;
      if (newCurrentIndex >= newResults.length) {
        newCurrentIndex = newResults.length - 1;
      }

      emit(currentState.copyWith(captureResults: newResults, currentPhotoIndex: newCurrentIndex));
    }
  }

  /// Cambia el índice de la foto actual (para navegación)
  void changeCurrentPhoto(int index) {
    if (state is! PhotoEvidenceSuccess) return;

    final currentState = state as PhotoEvidenceSuccess;
    if (index < 0 || index >= currentState.captureResults.length) return;

    emit(currentState.copyWith(currentPhotoIndex: index));
  }

  /// Elimina todas las fotos y reinicia
  void retakeAllPhotos() {
    emit(const PhotoEvidenceInitial());
  }

  /// Intenta recuperarse de un error manteniendo las fotos existentes
  void retryFromError() {
    if (state is! PhotoEvidenceError) return;

    final errorState = state as PhotoEvidenceError;
    if (errorState.hasExistingPhotos) {
      emit(
        PhotoEvidenceSuccess(captureResults: errorState.captureResults, currentPhotoIndex: errorState.captureResults.length - 1),
      );
    } else {
      emit(const PhotoEvidenceInitial());
    }
  }

  /// Envía las evidencias al servidor
  Future<bool> sendData() async {
    if (state is! PhotoEvidenceSuccess) return false;

    final currentState = state as PhotoEvidenceSuccess;
    if (!currentState.hasPhotos) return false;

    emit(PhotoEvidenceLoading(message: 'Enviando evidencia...', captureResults: currentState.captureResults));

    try {
      await _saveToGallery(currentState.captureResults.map((r) => r.imagePath).toList());
      HapticFeedback.lightImpact();
      emit(currentState);
      return true;
    } on SocketException {
      emit(PhotoEvidenceError(message: 'Error de conexión. Verifica tu internet.', captureResults: currentState.captureResults));
      return false;
    } on HttpException catch (error) {
      emit(PhotoEvidenceError(message: error.message, captureResults: currentState.captureResults));
      return false;
    } catch (err) {
      emit(PhotoEvidenceError(message: 'Error inesperado al enviar evidencia', captureResults: currentState.captureResults));
      return false;
    }
  }

  /// Guarda las evidencias localmente
  Future<bool> saveLocally() async {
    if (state is! PhotoEvidenceSuccess) return false;

    final currentState = state as PhotoEvidenceSuccess;
    if (!currentState.hasPhotos) return false;

    emit(PhotoEvidenceLoading(message: 'Guardando evidencias...', captureResults: currentState.captureResults));

    try {
      final success = await _saveToGallery(currentState.captureResults.map((r) => r.imagePath).toList());
      if (success) {
        // Volver al estado de éxito
        emit(currentState);
        return true;
      } else {
        emit(
          PhotoEvidenceError(
            message: 'No se pudieron guardar las evidencias. Verifica los permisos.',
            captureResults: currentState.captureResults,
          ),
        );
        return false;
      }
    } catch (e) {
      emit(
        PhotoEvidenceError(message: 'Error inesperado al guardar las evidencias', captureResults: currentState.captureResults),
      );
      return false;
    }
  }

  /// Verifica si se pueden capturar más fotos
  bool canCaptureMorePhotos() {
    if (state is PhotoEvidenceSuccess) {
      final currentState = state as PhotoEvidenceSuccess;
      return currentState.captureResults.length < _config.maxPhotos;
    }

    return true;
  }

  /// Obtiene la configuración actual
  ReceiptCaptureConfig get config => _config;

  /// Método privado para guardar en galería
  Future<bool> _saveToGallery(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return false;

    try {
      bool allSaved = true;

      for (int i = 0; i < imagePaths.length; i++) {
        final success = await _mediaRepository.saveImageToGallery(imagePaths[i]);
        if (!success) {
          allSaved = false;
          break;
        }
      }

      return allSaved;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene o crea el use case con lazy loading inteligente
  Future<TakePhotoEvidence> _getOrCreateUseCase() async {
    // Si ya tenemos un use case, usarlo
    if (_lazyUseCase != null && _isInitialized) {
      return _lazyUseCase!;
    }

    final enableOCR = _config.enableOCR || _config.evidenceType == EvidenceCaptureType.invoice;

    _lazyUseCase = _captureUseCase;

    // Inicializar ML Kit solo la primera vez
    if (enableOCR && !_isInitialized) {
      await _lazyUseCase!.initialize();
      _isInitialized = true;
    }

    return _lazyUseCase!;
  }

  @override
  Future<void> close() {
    _captureUseCase.dispose();
    _lazyUseCase?.dispose();
    return super.close();
  }
}
