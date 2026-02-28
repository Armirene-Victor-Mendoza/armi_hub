class BusinessContext {
  const BusinessContext({required this.businessId, required this.storeId});

  final int businessId;
  final String storeId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'business_id': businessId,
      'store_id': storeId,
    };
  }

  factory BusinessContext.fromJson(Map<String, dynamic> json) {
    return BusinessContext(
      businessId: json['business_id'] as int,
      storeId: json['store_id'] as String,
    );
  }
}
