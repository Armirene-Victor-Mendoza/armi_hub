import '../domain/media_picker_repository.dart';
import '../domain/use_cases/pick_media_from_gallery_use_case.dart';
import '../domain/use_cases/take_media_with_camera_use_case.dart';
import '../data/media_picker_repository_impl.dart';

/// Utilidad para selección de fotos que cumple con políticas de Google Play
///
/// Ahora usa Photo Picker que NO requiere permisos READ_MEDIA_IMAGES/READ_MEDIA_VIDEO
/// Mantiene compatibilidad con código existente pero internamente usa arquitectura limpia.
class PhotoPickerHelper {
  static final MediaPickerRepository _repository = MediaPickerRepositoryImpl();
  static final PickMediaFromGalleryUseCase _pickFromGalleryUseCase = PickMediaFromGalleryUseCase(_repository);
  static final TakeMediaWithCameraUseCase _takeWithCameraUseCase = TakeMediaWithCameraUseCase(_repository);

  /// Toma una foto usando la cámara
  /// Requiere permiso CAMERA (que sí está permitido por Google Play)
  static Future<String?> takePhoto({
    int imageQuality = 85,
  }) async {
    try {
      final result = await _takeWithCameraUseCase.takePhoto(
        imageQuality: imageQuality,
      );
      return result?.firstPath;
    } catch (e) {
      return null;
    }
  }

  /// Selecciona una foto desde galería usando Photo Picker
  ///
  /// ✅ AHORA HABILITADO - Usa Photo Picker que NO requiere permisos
  /// Compatible con Android 13+ y versiones anteriores usando FilePicker
  static Future<String?> pickFromGallery({
    int imageQuality = 85,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await _pickFromGalleryUseCase.pickImage(
        imageQuality: imageQuality,
        allowMultiple: allowMultiple,
      );
      return result?.firstPath;
    } on MediaPickerNotSupportedException {
      throw UnsupportedError('Photo Picker no está disponible en este dispositivo');
    } catch (e) {
      return null;
    }
  }

  /// Selecciona múltiples fotos desde galería usando Photo Picker
  static Future<List<String>?> pickMultipleFromGallery({
    int imageQuality = 85,
  }) async {
    try {
      final result = await _pickFromGalleryUseCase.pickImage(
        imageQuality: imageQuality,
        allowMultiple: true,
      );
      return result?.paths;
    } on MediaPickerNotSupportedException {
      throw UnsupportedError('Photo Picker no está disponible en este dispositivo');
    } catch (e) {
      return null;
    }
  }

  /// Selecciona cualquier tipo de media (imagen o video)
  static Future<String?> pickAnyMedia({
    int imageQuality = 85,
  }) async {
    try {
      final result = await _pickFromGalleryUseCase.pickAnyMedia(
        imageQuality: imageQuality,
      );
      return result?.firstPath;
    } on MediaPickerNotSupportedException {
      throw UnsupportedError('Photo Picker no está disponible en este dispositivo');
    } catch (e) {
      return null;
    }
  }

  /// Selecciona archivos (cualquier tipo) usando el selector del sistema
  /// Mantiene compatibilidad con Android 7+ solicitando permiso solo si es necesario
  static Future<List<String>?> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await _repository.pickFiles(
        MediaPickerConfig(
          type: MediaType.any,
          allowMultiple: allowMultiple,
          allowedExtensions: allowedExtensions,
        ),
      );
      return result?.paths;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si Photo Picker está disponible
  static Future<bool> get isPhotoPickerAvailable => _repository.isPhotoPickerAvailable();

  /// Verifica si el dispositivo soporta tomar fotos
  static bool get canTakePhotos => _repository.isCameraAvailable;

  /// Mensaje informativo sobre Photo Picker
  static const String photoPickerInfoMessage = 'Ahora usamos Photo Picker que no requiere permisos especiales. '
      'Puedes seleccionar fotos desde tu galería de forma segura.';
}
