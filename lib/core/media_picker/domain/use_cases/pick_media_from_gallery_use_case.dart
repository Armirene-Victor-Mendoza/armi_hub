import '../media_picker_repository.dart';

/// Caso de uso para seleccionar fotos/videos desde galería usando Photo Picker
class PickMediaFromGalleryUseCase {
  final MediaPickerRepository _repository;

  const PickMediaFromGalleryUseCase(this._repository);

  /// Selecciona una imagen desde galería usando Photo Picker (sin permisos)
  Future<MediaPickerResult?> pickImage({
    bool allowMultiple = false,
    int imageQuality = 85,
  }) async {
    if (!await _repository.isPhotoPickerAvailable()) {
      throw const MediaPickerNotSupportedException('Photo Picker no está disponible en este dispositivo');
    }

    final config = MediaPickerConfig(
      type: MediaType.image,
      allowMultiple: allowMultiple,
      imageQuality: imageQuality,
    );

    return _repository.pickFromGallery(config);
  }

  /// Selecciona un video desde galería usando Photo Picker (sin permisos)
  Future<MediaPickerResult?> pickVideo({
    bool allowMultiple = false,
  }) async {
    if (!await _repository.isPhotoPickerAvailable()) {
      throw const MediaPickerNotSupportedException('Photo Picker no está disponible en este dispositivo');
    }

    final config = MediaPickerConfig(
      type: MediaType.video,
      allowMultiple: allowMultiple,
    );

    return _repository.pickFromGallery(config);
  }

  /// Selecciona cualquier tipo de media (imagen o video)
  Future<MediaPickerResult?> pickAnyMedia({
    bool allowMultiple = false,
    int imageQuality = 85,
  }) async {
    if (!await _repository.isPhotoPickerAvailable()) {
      throw const MediaPickerNotSupportedException('Photo Picker no está disponible en este dispositivo');
    }

    final config = MediaPickerConfig(
      type: MediaType.any,
      allowMultiple: allowMultiple,
      imageQuality: imageQuality,
    );

    return _repository.pickFromGallery(config);
  }
}
