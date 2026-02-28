enum OrderSyncStatus { pending, success, error }

extension OrderSyncStatusX on OrderSyncStatus {
  String get value {
    switch (this) {
      case OrderSyncStatus.pending:
        return 'pending';
      case OrderSyncStatus.success:
        return 'success';
      case OrderSyncStatus.error:
        return 'error';
    }
  }

  static OrderSyncStatus fromValue(String value) {
    switch (value) {
      case 'pending':
        return OrderSyncStatus.pending;
      case 'success':
        return OrderSyncStatus.success;
      case 'error':
      default:
        return OrderSyncStatus.error;
    }
  }
}
