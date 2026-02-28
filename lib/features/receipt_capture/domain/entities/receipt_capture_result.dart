import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_data.dart';

/// Resultado de la captura y procesamiento de recibo
class ReceiptCaptureResult {
  final bool success;
  final String imagePath;
  final String optimizedImagePath;
  final ReceiptData? receiptData;
  final String? error;
  final List<String> warnings;

  const ReceiptCaptureResult({
    required this.success,
    required this.imagePath,
    required this.optimizedImagePath,
    this.receiptData,
    this.error,
    this.warnings = const [],
  });

  factory ReceiptCaptureResult.success({
    required String imagePath,
    required String optimizedImagePath,
    ReceiptData? receiptData,
    List<String> warnings = const [],
  }) {
    return ReceiptCaptureResult(
      success: true,
      imagePath: imagePath,
      optimizedImagePath: optimizedImagePath,
      receiptData: receiptData,
      warnings: warnings,
    );
  }

  factory ReceiptCaptureResult.error({required String error, String imagePath = '', String optimizedImagePath = ''}) {
    return ReceiptCaptureResult(success: false, imagePath: imagePath, optimizedImagePath: optimizedImagePath, error: error);
  }

  /// Indica si tiene datos de OCR válidos
  bool get hasValidOCRData => receiptData?.hasMinimumFields ?? false;

  /// Indica si al menos tiene imágenes
  bool get hasImages => imagePath.isNotEmpty;
}
