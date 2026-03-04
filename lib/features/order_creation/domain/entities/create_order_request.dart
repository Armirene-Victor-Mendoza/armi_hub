class CreateOrderRequest {
  const CreateOrderRequest({
    required this.totalValue,
    required this.paymentMethod,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.businessId,
    required this.storeId,
    required this.city,
    required this.urlImage,
  });

  final double totalValue;
  final int paymentMethod;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final int businessId;
  final String storeId;
  final String city;
  final String urlImage;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_value': totalValue,
      'payment_method': paymentMethod,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'phone': phone,
      'business_id': businessId,
      'store_id': storeId,
      'city': city,
      'url_image': urlImage,
    };
  }
}
