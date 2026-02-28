import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/media_picker_repository.dart';

/// Implementación del repositorio de media picker que cumple con políticas de Google Play
class MediaPickerRepositoryImpl implements MediaPickerRepository {
  final ImagePicker _imagePicker;

  MediaPickerRepositoryImpl({ImagePicker? imagePicker}) : _imagePicker = imagePicker ?? ImagePicker();

  Future<int?> _getAndroidSdkInt() async {
    if (!Platform.isAndroid) return null;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  Future<void> _ensureLegacyStoragePermissionIfNeeded() async {
    final sdkInt = await _getAndroidSdkInt();
    // Android 10+ usa Scoped Storage/Photo Picker, no requiere permiso.
    if (sdkInt == null || sdkInt >= 29) return;

    final permission = Permission.storage;
    final status = await permission.status;

    if (status == PermissionStatus.granted) return;

    if (status == PermissionStatus.permanentlyDenied) {
      throw const MediaPickerException(
        'Permiso de almacenamiento denegado permanentemente. Habilítalo desde ajustes para continuar.',
      );
    }

    final requested = await permission.request();
    if (requested != PermissionStatus.granted) {
      throw const MediaPickerException('Permiso de almacenamiento denegado para acceder a la galería/archivos');
    }
  }

  Future<void> _ensureCameraPermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final status = await Permission.camera.status;

    if (status == PermissionStatus.granted) return;

    if (status == PermissionStatus.permanentlyDenied) {
      throw const MediaPickerException('Permiso de cámara denegado permanentemente. Habilítalo desde ajustes.');
    }

    final requested = await Permission.camera.request();
    if (requested != PermissionStatus.granted) {
      throw const MediaPickerException('Permiso de cámara denegado por el usuario');
    }
  }

  Future<String> _persistFileBytes(PlatformFile file) async {
    final directory = await getTemporaryDirectory();
    final sanitizedName =
        (file.name.isNotEmpty ? file.name : 'file_${DateTime.now().millisecondsSinceEpoch}').replaceAll(RegExp(r'[\\/]'), '_');
    final tempFile = File('${directory.path}/$sanitizedName');
    await tempFile.writeAsBytes(file.bytes!);
    return tempFile.path;
  }

  Future<String> _persistBytes(Uint8List bytes, PlatformFile file) async {
    final directory = await getTemporaryDirectory();
    final sanitizedName =
        (file.name.isNotEmpty ? file.name : 'file_${DateTime.now().millisecondsSinceEpoch}').replaceAll(RegExp(r'[\\/]'), '_');
    final tempFile = File('${directory.path}/$sanitizedName');
    await tempFile.writeAsBytes(bytes);
    return tempFile.path;
  }

  @override
  Future<MediaPickerResult?> pickFromGallery(MediaPickerConfig config) async {
    try {
      // Android 7-9 requieren permiso de almacenamiento para exponer la ruta real.
      await _ensureLegacyStoragePermissionIfNeeded();

      // Usar FilePicker que actúa como Photo Picker en Android 13+
      // y no requiere permisos READ_MEDIA_*
      FileType fileType;
      List<String>? allowedExtensions;

      switch (config.type) {
        case MediaType.image:
          fileType = FileType.image;
          allowedExtensions = null; // FilePicker maneja automáticamente
          break;
        case MediaType.video:
          fileType = FileType.video;
          allowedExtensions = null;
          break;
        case MediaType.any:
          fileType = FileType.media; // Imágenes y videos
          allowedExtensions = null;
          break;
      }

      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: config.allowMultiple,
        withData: true, // Necesario para Photo Picker (Android 13+) cuando no hay path directa
      );

      if (result == null || result.files.isEmpty) {
        return null; // Usuario canceló
      }

      final paths = <String>[];

      for (final file in result.files) {
        if (file.path != null) {
          paths.add(file.path!);
        } else if (file.bytes != null) {
          // Photo Picker en Android 13+ entrega bytes, los persistimos temporalmente
          final persistedPath = await _persistFileBytes(file);
          paths.add(persistedPath);
        } else if (file.readStream != null) {
          // Fallback: leer stream cuando el plugin no devuelve bytes
          final bytes = await file.readStream!.fold<BytesBuilder>(BytesBuilder(), (b, data) {
            b.add(data);
            return b;
          }).then((b) => b.takeBytes());
          final persistedPath = await _persistBytes(bytes, file);
          paths.add(persistedPath);
        }
      }

      if (paths.isEmpty) {
        throw const MediaPickerException('No se pudieron obtener las rutas de los archivos seleccionados');
      }

      return MediaPickerResult(
        paths: paths,
        type: config.type,
        source: MediaSource.gallery,
      );
    } catch (e) {
      if (e is MediaPickerException) rethrow;
      throw MediaPickerException('Error al seleccionar desde galería', e);
    }
  }

  @override
  Future<MediaPickerResult?> takeFromCamera(MediaPickerConfig config) async {
    try {
      if (!isCameraAvailable) {
        throw const MediaPickerNotSupportedException('La cámara no está disponible en este dispositivo');
      }

      await _ensureCameraPermission();

      // Android 7-9 pueden requerir almacenamiento para escribir el archivo temporal que devuelve el intent de cámara
      await _ensureLegacyStoragePermissionIfNeeded();

      XFile? file;

      switch (config.type) {
        case MediaType.image:
          file = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: config.imageQuality,
          );
          break;
        case MediaType.video:
          file = await _imagePicker.pickVideo(
            source: ImageSource.camera,
          );
          break;
        case MediaType.any:
          // Por defecto, tomar foto
          file = await _imagePicker.pickImage(
            source: ImageSource.camera,
            imageQuality: config.imageQuality,
          );
          break;
      }

      if (file == null) {
        return null; // Usuario canceló
      }

      return MediaPickerResult(
        paths: [file.path],
        type: config.type,
        source: MediaSource.camera,
      );
    } catch (e) {
      if (e is MediaPickerException) rethrow;
      throw MediaPickerException('Error al tomar desde cámara', e);
    }
  }

  @override
  Future<MediaPickerResult?> pickFiles(MediaPickerConfig config) async {
    try {
      // Android 7-9 requieren permiso para exponer ruta absoluta
      await _ensureLegacyStoragePermissionIfNeeded();

      final hasCustomExtensions = config.allowedExtensions != null && config.allowedExtensions!.isNotEmpty;

      final result = await FilePicker.platform.pickFiles(
        type: hasCustomExtensions ? FileType.custom : FileType.any,
        allowedExtensions: config.allowedExtensions,
        allowMultiple: config.allowMultiple,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null; // Usuario canceló
      }

      final paths = <String>[];
      for (final file in result.files) {
        if (file.path != null) {
          paths.add(file.path!);
        } else if (file.bytes != null) {
          final persistedPath = await _persistFileBytes(file);
          paths.add(persistedPath);
        } else if (file.readStream != null) {
          final bytes = await file.readStream!.fold<BytesBuilder>(BytesBuilder(), (b, data) {
            b.add(data);
            return b;
          }).then((b) => b.takeBytes());
          final persistedPath = await _persistBytes(bytes, file);
          paths.add(persistedPath);
        }
      }

      if (paths.isEmpty) {
        throw const MediaPickerException('No se pudieron obtener las rutas de los archivos seleccionados');
      }

      return MediaPickerResult(
        paths: paths,
        type: config.type,
        source: MediaSource.files,
      );
    } catch (e) {
      if (e is MediaPickerException) rethrow;
      throw MediaPickerException('Error al seleccionar archivos', e);
    }
  }

  @override
  Future<bool> isPhotoPickerAvailable() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      // Android Photo Picker nativo desde 13; en 7-12 se usa SAF sin permisos extras
      return sdkInt != null && sdkInt >= 24;
    }

    return Platform.isIOS;
  }

  @override
  bool get isCameraAvailable => Platform.isAndroid || Platform.isIOS;

  @override
  Future<bool> saveImageToGallery(String imagePath) async {
    try {
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }

      // Verificar y solicitar permisos si es necesario
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkInt();

        // Solo necesitamos permisos en Android 7-9 (API 24-28)
        if (sdkInt != null && sdkInt < 29) {
          final permission = Permission.storage;
          final status = await permission.status;

          if (status != PermissionStatus.granted) {
            final requested = await permission.request();
            if (requested != PermissionStatus.granted) {
              return false; // Permisos denegados
            }
          }
        }
        // Android 10+ usa Scoped Storage automáticamente, no necesita permisos
      }

      // Leer el archivo como bytes
      final Uint8List imageBytes = await file.readAsBytes();

      // Guardar usando image_gallery_saver_plus
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 90,
        name: 'armirene_${DateTime.now().millisecondsSinceEpoch}',
        isReturnImagePathOfIOS: true,
      );

      // Verificar el resultado
      if (result != null) {
        if (result is Map) {
          return result['isSuccess'] == true;
        }
        return true; // Si no es Map pero no es null, consideramos éxito
      }

      return false;
    } catch (e) {
      return false; // En caso de cualquier error, retornar false
    }
  }
}
