class UploadImageResult {
  const UploadImageResult({
    required this.success,
    required this.statusCode,
    required this.responseBodyRaw,
    this.urlImage,
    this.errorMessage,
  });

  final bool success;
  final int? statusCode;
  final String responseBodyRaw;
  final String? urlImage;
  final String? errorMessage;
}
