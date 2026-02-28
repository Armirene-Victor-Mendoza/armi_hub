import 'dart:io';
import 'dart:typed_data';
import 'package:armi_hub/features/receipt_capture/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio para reconocimiento de texto usando Google ML Kit
class MLKitTextRecognitionService implements ITextRecognitionService {
  static final MLKitTextRecognitionService _instance = MLKitTextRecognitionService._internal();
  factory MLKitTextRecognitionService() => _instance;
  MLKitTextRecognitionService._internal();

  TextRecognizer? _textRecognizer;
  bool _isInitialized = false;

  /// Inicializa el reconocedor de texto optimizado para español
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar el reconocedor específicamente para texto latino (español)
      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin, // Optimizado para español, portugués y otros idiomas latinos
      );
      _isInitialized = true;
      debugPrint('MLKit Text Recognition inicializado correctamente para texto en español');
    } catch (e) {
      throw Exception('Error inicializando MLKit Text Recognition: $e');
    }
  }

  /// Libera los recursos del reconocedor
  @override
  Future<void> dispose() async {
    if (_isInitialized) {
      await _textRecognizer?.close();
      _isInitialized = false;
    }
  }

  /// Verifica si el servicio está disponible
  @override
  bool get isAvailable => _isInitialized;

  /// Reconoce texto desde un archivo de imagen
  @override
  Future<TextRecognitionResult> recognizeTextFromFile(String imagePath) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        return TextRecognitionResult.error('El archivo de imagen no existe: $imagePath');
      }

      // Crear InputImage desde el archivo
      final inputImage = InputImage.fromFilePath(imagePath);

      return await _recognizeText(inputImage);
    } catch (e) {
      return TextRecognitionResult.error('Error procesando imagen: $e');
    }
  }

  /// Reconoce texto desde bytes de imagen
  @override
  Future<TextRecognitionResult> recognizeTextFromBytes(Uint8List bytes, int width, int height) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Crear InputImage desde bytes
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21, // Formato común en Android
          bytesPerRow: width, // Bytes por fila
        ),
      );

      return await _recognizeText(inputImage);
    } catch (e) {
      return TextRecognitionResult.error('Error procesando bytes de imagen: $e');
    }
  }

  /// Método privado para realizar el reconocimiento
  Future<TextRecognitionResult> _recognizeText(InputImage inputImage) async {
    try {
      if (_textRecognizer == null) {
        return TextRecognitionResult.error('El reconocedor de texto no está inicializado');
      }

      // Procesar la imagen con ML Kit
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

      // Usar directamente el texto de ML Kit sin modificaciones
      final extractedText = recognizedText.text.trim();

      // Calcular confianza promedio
      double totalConfidence = 0.0;
      int elementCount = 0;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            if (element.confidence != null) {
              totalConfidence += element.confidence!;
              elementCount++;
            }
          }
        }
      }

      final averageConfidence = elementCount > 0 ? totalConfidence / elementCount : 0.0;

      if (extractedText.isEmpty) {
        return TextRecognitionResult.error('No se pudo extraer texto de la imagen');
      }

      return TextRecognitionResult.success(extractedText, confidence: averageConfidence);
    } catch (e) {
      return TextRecognitionResult.error('Error en el reconocimiento de texto: $e');
    }
  }

  /// Obtiene información detallada de bloques de texto (para debugging)
  @override
  Future<Map<String, dynamic>> getDetailedTextInfo(String imagePath) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

      final List<Map<String, dynamic>> blocks = [];

      for (TextBlock block in recognizedText.blocks) {
        final List<Map<String, dynamic>> lines = [];

        for (TextLine line in block.lines) {
          final List<Map<String, dynamic>> elements = [];

          for (TextElement element in line.elements) {
            elements.add({
              'text': element.text,
              'confidence': element.confidence,
              'boundingBox': {
                'left': element.boundingBox.left,
                'top': element.boundingBox.top,
                'right': element.boundingBox.right,
                'bottom': element.boundingBox.bottom,
              },
            });
          }

          lines.add({
            'text': line.text,
            'confidence': line.confidence,
            'elements': elements,
            'boundingBox': {
              'left': line.boundingBox.left,
              'top': line.boundingBox.top,
              'right': line.boundingBox.right,
              'bottom': line.boundingBox.bottom,
            },
          });
        }

        blocks.add({
          'text': block.text,
          'lines': lines,
          'boundingBox': {
            'left': block.boundingBox.left,
            'top': block.boundingBox.top,
            'right': block.boundingBox.right,
            'bottom': block.boundingBox.bottom,
          },
        });
      }

      return {'fullText': recognizedText.text, 'blocks': blocks, 'blockCount': blocks.length};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
