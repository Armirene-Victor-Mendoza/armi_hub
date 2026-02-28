import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_data.dart';

/// Resultado del procesamiento de recibo
class ReceiptProcessingResult {
  final bool success;
  final ReceiptData? receiptData;
  final String? error;
  final List<String> warnings;

  const ReceiptProcessingResult({required this.success, this.receiptData, this.error, this.warnings = const []});

  factory ReceiptProcessingResult.success(ReceiptData receiptData, {List<String> warnings = const []}) {
    return ReceiptProcessingResult(success: true, receiptData: receiptData, warnings: warnings);
  }

  factory ReceiptProcessingResult.error(String error) {
    return ReceiptProcessingResult(success: false, error: error);
  }
}
