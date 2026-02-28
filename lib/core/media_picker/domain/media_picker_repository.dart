/// Tipos de medios que se pueden seleccionar
enum MediaType {
  image,
  video,
  any,
}

/// Fuente de donde seleccionar medios
enum MediaSource {
  camera, // Cámara del dispositivo
  gallery, // Photo Picker del sistema (sin permisos)
  files, // Selector de archivos general
}

/// Resultado de la selección de medios
class MediaPickerResult {
  final List<String> paths;
  final MediaType type;
  final MediaSource source;

  const MediaPickerResult({
    required this.paths,
    required this.type,
    required this.source,
  });

  /// Indica si se seleccionó al menos un archivo
  bool get hasSelection => paths.isNotEmpty;

  /// Retorna el primer archivo seleccionado
  String? get firstPath => paths.isEmpty ? null : paths.first;

  /// Indica si es una selección múltiple
  bool get isMultiple => paths.length > 1;
}

/// Configuración para la selección de medios
class MediaPickerConfig {
  final MediaType type;
  final bool allowMultiple;
  final int? imageQuality; // 0-100, solo para cámara
  final int? maxFiles;
  final List<String>? allowedExtensions;

  const MediaPickerConfig({
    this.type = MediaType.image,
    this.allowMultiple = false,
    this.imageQuality = 85,
    this.maxFiles,
    this.allowedExtensions,
  });
}

/// Abstracción para la selección de medios
/// Cumple con las políticas de Google Play usando Photo Picker
abstract class MediaPickerRepository {
  /// Selecciona medios usando Photo Picker del sistema (sin permisos)
  Future<MediaPickerResult?> pickFromGallery(MediaPickerConfig config);

  /// Toma una foto/video usando la cámara (requiere permiso CAMERA)
  Future<MediaPickerResult?> takeFromCamera(MediaPickerConfig config);

  /// Selecciona archivos usando el selector de archivos del sistema
  Future<MediaPickerResult?> pickFiles(MediaPickerConfig config);

  /// Verifica si Photo Picker está disponible en el dispositivo
  Future<bool> isPhotoPickerAvailable();

  /// Verifica si la cámara está disponible
  bool get isCameraAvailable;

  /// Guarda una imagen en la galería desde un path
  /// Verifica y solicita permisos si es necesario
  /// Retorna true si fue exitoso, false si no
  Future<bool> saveImageToGallery(String imagePath);
}

/// Excepción cuando la funcionalidad no está soportada
class MediaPickerNotSupportedException implements Exception {
  final String message;
  const MediaPickerNotSupportedException(this.message);
}

/// Excepción cuando el usuario cancela la selección
class MediaPickerCancelledException implements Exception {
  const MediaPickerCancelledException();
}

/// Excepción cuando ocurre un error durante la selección
class MediaPickerException implements Exception {
  final String message;
  final Object? originalError;

  const MediaPickerException(this.message, [this.originalError]);
}
