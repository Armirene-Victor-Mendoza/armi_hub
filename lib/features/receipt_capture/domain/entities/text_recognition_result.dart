/// Resultado del reconocimiento de texto
class TextRecognitionResult {
  final bool success;
  final String? text;
  final String? error;
  final double confidence;

  const TextRecognitionResult({
    required this.success,
    this.text,
    this.error,
    this.confidence = 0.0,
  });

  factory TextRecognitionResult.success(String text, {double confidence = 1.0}) {
    return TextRecognitionResult(
      success: true,
      text: text,
      confidence: confidence,
    );
  }

  factory TextRecognitionResult.error(String error) {
    return TextRecognitionResult(
      success: false,
      error: error,
    );
  }
}
