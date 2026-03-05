class CreateOrderResult {
  const CreateOrderResult({
    required this.success,
    required this.orderCreated,
    required this.manualCreationRequired,
    required this.statusCode,
    required this.responseBodyRaw,
    this.errorMessage,
    this.userMessage,
    this.publicOrderId,
    this.businessOrderId,
    this.backendStatus,
    this.backendMessage,
  });

  final bool success;
  final bool orderCreated;
  final bool manualCreationRequired;
  final int? statusCode;
  final String responseBodyRaw;
  final String? errorMessage;
  final String? userMessage;
  final String? publicOrderId;
  final String? businessOrderId;
  final String? backendStatus;
  final String? backendMessage;
}
