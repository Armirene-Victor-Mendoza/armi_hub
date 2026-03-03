import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';
import 'package:armi_hub/features/app_context/domain/repositories/app_context_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppContextRepositoryImpl implements AppContextRepository {
  static const String _businessIdKey = 'business_id';
  static const String _storeIdKey = 'store_id';
  static const String _businessNameKey = 'business_name';
  static const String _storeNameKey = 'store_name';

  @override
  Future<void> saveBusinessContext(BusinessContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_businessIdKey, context.businessId);
    await prefs.setString(_storeIdKey, context.storeId);
    if (context.businessName != null) {
      await prefs.setString(_businessNameKey, context.businessName!);
    } else {
      await prefs.remove(_businessNameKey);
    }
    if (context.storeName != null) {
      await prefs.setString(_storeNameKey, context.storeName!);
    } else {
      await prefs.remove(_storeNameKey);
    }
  }

  @override
  Future<BusinessContext?> getBusinessContext() async {
    final prefs = await SharedPreferences.getInstance();

    final businessId = prefs.getInt(_businessIdKey);
    final storeId = prefs.getString(_storeIdKey);
    final businessName = prefs.getString(_businessNameKey);
    final storeName = prefs.getString(_storeNameKey);

    if (businessId == null || storeId == null || storeId.trim().isEmpty) {
      return null;
    }

    return BusinessContext(
      businessId: businessId,
      storeId: storeId,
      businessName: businessName,
      storeName: storeName,
    );
  }

  @override
  Future<void> clearBusinessContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_businessIdKey);
    await prefs.remove(_storeIdKey);
    await prefs.remove(_businessNameKey);
    await prefs.remove(_storeNameKey);
  }
}
