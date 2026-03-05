class CreateOrderResult {
  const CreateOrderResult({
    required this.success,
    required this.statusCode,
    required this.responseBodyRaw,
    this.errorMessage,
    this.publicOrderId,
    this.businessOrderId,
    this.backendStatus,
    this.backendMessage,
  });

  final bool success;
  final int? statusCode;
  final String responseBodyRaw;
  final String? errorMessage;
  final String? publicOrderId;
  final String? businessOrderId;
  final String? backendStatus;
  final String? backendMessage;
}
