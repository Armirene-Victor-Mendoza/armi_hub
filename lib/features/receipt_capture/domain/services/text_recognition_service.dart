import 'dart:typed_data';

import 'package:armi_hub/features/receipt_capture/domain/entities/text_recognition_result.dart';

abstract class ITextRecognitionService {
  Future<void> initialize();
  Future<void> dispose();
  bool get isAvailable;
  Future<TextRecognitionResult> recognizeTextFromFile(String imagePath);
  Future<TextRecognitionResult> recognizeTextFromBytes(Uint8List bytes, int width, int height);
  Future<Map<String, dynamic>> getDetailedTextInfo(String imagePath);
}
