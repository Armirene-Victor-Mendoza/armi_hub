class CreateOrderResult {
  const CreateOrderResult({
    required this.success,
    required this.statusCode,
    required this.responseBodyRaw,
    this.errorMessage,
  });

  final bool success;
  final int? statusCode;
  final String responseBodyRaw;
  final String? errorMessage;
}
