import '../media_picker_repository.dart';

/// Caso de uso para tomar fotos/videos con la cámara
class TakeMediaWithCameraUseCase {
  final MediaPickerRepository _repository;

  const TakeMediaWithCameraUseCase(this._repository);

  /// Toma una foto con la cámara (requiere permiso CAMERA)
  Future<MediaPickerResult?> takePhoto({
    int imageQuality = 85,
  }) async {
    if (!_repository.isCameraAvailable) {
      throw const MediaPickerNotSupportedException('La cámara no está disponible en este dispositivo');
    }

    final config = MediaPickerConfig(
      type: MediaType.image,
      imageQuality: imageQuality,
    );

    return _repository.takeFromCamera(config);
  }

  /// Graba un video con la cámara (requiere permiso CAMERA)
  Future<MediaPickerResult?> takeVideo() async {
    if (!_repository.isCameraAvailable) {
      throw const MediaPickerNotSupportedException('La cámara no está disponible en este dispositivo');
    }

    final config = MediaPickerConfig(
      type: MediaType.video,
    );

    return _repository.takeFromCamera(config);
  }
}
