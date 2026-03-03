class BranchOffice {
  const BranchOffice({
    required this.id,
    required this.businessOwner,
    required this.name,
    required this.city,
    required this.state,
    required this.address,
    this.phone,
  });

  final int id;
  final int businessOwner;
  final String name;
  final String city;
  final String state;
  final String address;
  final String? phone;

  String get storeId => id.toString();

  factory BranchOffice.fromJson(Map<String, dynamic> json) {
    return BranchOffice(
      id: json['id'] as int,
      businessOwner: json['businessOwner'] as int,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}
