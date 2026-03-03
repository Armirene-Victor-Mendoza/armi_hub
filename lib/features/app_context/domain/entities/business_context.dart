import 'package:equatable/equatable.dart';

class BusinessContext extends Equatable {
  const BusinessContext({
    required this.businessId,
    required this.storeId,
    this.businessName,
    this.storeName,
  });

  final int businessId;
  final String storeId;
  final String? businessName;
  final String? storeName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'business_id': businessId,
      'store_id': storeId,
      'business_name': businessName,
      'store_name': storeName,
    };
  }

  factory BusinessContext.fromJson(Map<String, dynamic> json) {
    return BusinessContext(
      businessId: json['business_id'] as int,
      storeId: json['store_id'] as String,
      businessName: json['business_name'] as String?,
      storeName: json['store_name'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[businessId, storeId, businessName, storeName];
}
