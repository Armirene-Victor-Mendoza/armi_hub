import 'dart:typed_data';

import 'package:armi_hub/features/receipt_capture/data/data.dart';
import 'package:armi_hub/features/receipt_capture/domain/entities/receipt_processing_result.dart';
import 'package:armi_hub/features/receipt_capture/domain/services/receipt_parser.dart';
import 'package:armi_hub/features/receipt_capture/domain/services/text_recognition_service.dart';

/// Use case principal para el reconocimiento y procesamiento de recibos
class ProcessReceipt {
  final ITextRecognitionService _textRecognitionService;
  final IReceiptParser _parser;
  ProcessReceipt({ITextRecognitionService? textRecognitionService, IReceiptParser? parser})
    : _textRecognitionService = textRecognitionService ?? MLKitTextRecognitionService(),
      _parser = parser ?? PosReceiptParser();

  /// Inicializa los servicios necesarios
  Future<void> initialize() async {
    await _textRecognitionService.initialize();
  }

  /// Libera los recursos
  Future<void> dispose() async {
    await _textRecognitionService.dispose();
  }

  /// Verifica si los servicios están disponibles
  bool get isAvailable => _textRecognitionService.isAvailable;

  /// Procesa un recibo desde un archivo de imagen
  Future<ReceiptProcessingResult> processReceiptFromFile(String imagePath) async {
    try {
      // Paso 1: Extraer texto de la imagen
      final textResult = await _textRecognitionService.recognizeTextFromFile(imagePath);

      if (!textResult.success) {
        return ReceiptProcessingResult.error('Error extrayendo texto: ${textResult.error ?? 'Error desconocido'}');
      }

      final extractedText = textResult.text!;

      // final debugResult = await _getDebugInfo(imagePath);
      // print('Debug Info: $debugResult');

      // Paso 2: Procesar el texto extraído
      return await _processExtractedText(extractedText);
    } catch (e) {
      return ReceiptProcessingResult.error('Error procesando recibo: $e');
    }
  }

  /// Procesa un recibo desde bytes de imagen
  Future<ReceiptProcessingResult> processReceiptFromBytes(Uint8List bytes, int width, int height) async {
    try {
      // Paso 1: Extraer texto de los bytes
      final textResult = await _textRecognitionService.recognizeTextFromBytes(bytes, width, height);

      if (!textResult.success) {
        return ReceiptProcessingResult.error('Error extrayendo texto: ${textResult.error ?? 'Error desconocido'}');
      }

      final extractedText = textResult.text!;

      // Paso 2: Procesar el texto extraído
      return await _processExtractedText(extractedText);
    } catch (e) {
      return ReceiptProcessingResult.error('Error procesando recibo: $e');
    }
  }

  /// Procesa texto ya extraído (útil para testing)
  Future<ReceiptProcessingResult> processExtractedText(String text) async {
    return await _processExtractedText(text);
  }

  /// Método privado para procesar el texto extraído
  Future<ReceiptProcessingResult> _processExtractedText(String text) async {
    try {
      // Validar que el texto no esté vacío
      if (text.trim().isEmpty) {
        return ReceiptProcessingResult.error('No se extrajo texto de la imagen');
      }

      // Procesar con el extractor de datos
      return _parser.parse(text);
    } catch (e) {
      return ReceiptProcessingResult.error('Error procesando texto: $e');
    }
  }
}
