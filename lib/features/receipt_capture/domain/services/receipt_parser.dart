import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_processing_result.dart';

abstract class IReceiptParser {
  ReceiptProcessingResult parse(String rawText);
}
