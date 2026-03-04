import 'dart:io';
import 'package:armi_hub/core/media_picker/utils/photo_picker_helper.dart';
import 'package:armi_hub/features/receipt_capture/domain/domain.dart';
import 'package:armi_hub/features/receipt_capture/domain/repositories/image_optimizer_repository.dart';

/// Caso de uso para capturar fotos de recibos y procesar con OCR
class TakePhotoEvidence {
  final ProcessReceipt? _processReceiptUseCase;
  final ImageOptimizerRepository _imageOptimizer;
  final bool _enableOCR;

  TakePhotoEvidence({
    required bool enableOCR,
    ProcessReceipt? processReceiptUseCase,
    required ImageOptimizerRepository imageOptimizer,
  }) : _enableOCR = enableOCR,
       _processReceiptUseCase = enableOCR ? (processReceiptUseCase ?? ProcessReceipt()) : null,
       _imageOptimizer = imageOptimizer;

  /// Inicializa los servicios necesarios (solo si OCR está habilitado)
  Future<void> initialize() async {
    if (_enableOCR && _processReceiptUseCase != null) {
      await _processReceiptUseCase.initialize();
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    if (_processReceiptUseCase != null) {
      await _processReceiptUseCase.dispose();
    }
  }

  /// Verifica si los servicios están disponibles
  bool get isAvailable => !_enableOCR || (_processReceiptUseCase?.isAvailable ?? false);

  /// Captura una foto usando PhotoPickerHelper y procesa con OCR si está habilitado
  Future<ReceiptCaptureResult> capturePhoto({int imageQuality = 85}) async {
    try {
      // Paso 1: Capturar foto usando PhotoPickerHelper
      final imagePath = await PhotoPickerHelper.takePhoto(imageQuality: imageQuality);

      if (imagePath == null) {
        return ReceiptCaptureResult.error(error: 'No se pudo capturar la imagen');
      }

      return processImagePath(imagePath);
    } catch (e) {
      return ReceiptCaptureResult.error(error: 'Error capturando imagen: $e');
    }
  }

  /// Procesa una imagen existente (galería/archivos) con el mismo pipeline de cámara.
  Future<ReceiptCaptureResult> processImagePath(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ReceiptCaptureResult.error(error: 'El archivo de imagen no existe');
      }

      late final String optimizedImagePath;
      try {
        final optimizedFile = await _imageOptimizer.optimizeForUpload(file);
        optimizedImagePath = optimizedFile.path;
      } catch (_) {
        optimizedImagePath = imagePath;
      }

      if (_enableOCR && _processReceiptUseCase != null) {
        try {
          final ocrResult = await _processReceiptUseCase.processReceiptFromFile(imagePath);

          if (ocrResult.success && ocrResult.receiptData != null) {
            return ReceiptCaptureResult.success(
              imagePath: imagePath,
              optimizedImagePath: optimizedImagePath,
              receiptData: ocrResult.receiptData,
              warnings: ocrResult.warnings,
            );
          }

          return ReceiptCaptureResult.success(
            imagePath: imagePath,
            optimizedImagePath: optimizedImagePath,
            warnings: ['OCR no pudo procesar la imagen'],
          );
        } catch (e) {
          return ReceiptCaptureResult.success(
            imagePath: imagePath,
            optimizedImagePath: optimizedImagePath,
            warnings: ['Error procesando OCR: $e'],
          );
        }
      }

      return ReceiptCaptureResult.success(imagePath: imagePath, optimizedImagePath: optimizedImagePath);
    } catch (e) {
      return ReceiptCaptureResult.error(error: 'Error procesando imagen: $e');
    }
  }
}
