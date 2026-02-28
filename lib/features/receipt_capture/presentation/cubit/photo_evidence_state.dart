part of 'photo_evidence_cubit.dart';

abstract class PhotoEvidenceState extends Equatable {
  const PhotoEvidenceState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Widget recién inicializado
class PhotoEvidenceInitial extends PhotoEvidenceState {
  const PhotoEvidenceInitial();
}

/// Estado de captura - Cámara activa
class PhotoEvidenceCapturing extends PhotoEvidenceState {
  const PhotoEvidenceCapturing();
}

/// Estado de procesamiento - OCR y optimización en progreso
class PhotoEvidenceProcessing extends PhotoEvidenceState {
  const PhotoEvidenceProcessing();
}

/// Estado de éxito - Fotos capturadas y procesadas
class PhotoEvidenceSuccess extends PhotoEvidenceState {
  final List<ReceiptCaptureResult> captureResults;
  final int currentPhotoIndex;

  const PhotoEvidenceSuccess({
    required this.captureResults,
    this.currentPhotoIndex = 0,
  });

  @override
  List<Object?> get props => [captureResults, currentPhotoIndex];

  /// Copia el estado con nuevos valores
  PhotoEvidenceSuccess copyWith({
    List<ReceiptCaptureResult>? captureResults,
    int? currentPhotoIndex,
  }) {
    return PhotoEvidenceSuccess(
      captureResults: captureResults ?? this.captureResults,
      currentPhotoIndex: currentPhotoIndex ?? this.currentPhotoIndex,
    );
  }

  /// Getter para verificar si hay múltiples fotos
  bool get hasMultiplePhotos => captureResults.length > 1;

  /// Getter para verificar si hay fotos
  bool get hasPhotos => captureResults.isNotEmpty;

  /// Getter para verificar si hay datos de OCR
  bool get hasReceiptData => captureResults.any((result) => result.receiptData != null);
}

/// Estado de error - Fallo en captura o procesamiento
class PhotoEvidenceError extends PhotoEvidenceState {
  final String message;
  final List<ReceiptCaptureResult> captureResults; // Mantener fotos existentes si las hay

  const PhotoEvidenceError({
    required this.message,
    this.captureResults = const [],
  });

  @override
  List<Object> get props => [message, captureResults];

  /// Getter para verificar si hay fotos previas
  bool get hasExistingPhotos => captureResults.isNotEmpty;
}

/// Estado de carga para operaciones largas (envío, guardado)
class PhotoEvidenceLoading extends PhotoEvidenceState {
  final String message;
  final List<ReceiptCaptureResult> captureResults; // Mantener las fotos durante la carga

  const PhotoEvidenceLoading({
    required this.message,
    required this.captureResults,
  });

  @override
  List<Object> get props => [message, captureResults];
}
