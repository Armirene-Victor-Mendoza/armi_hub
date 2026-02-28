import 'package:armi_hub/features/app_context/domain/entities/business_context.dart';

abstract class AppContextRepository {
  Future<void> saveBusinessContext(BusinessContext context);

  Future<BusinessContext?> getBusinessContext();

  Future<void> clearBusinessContext();
}
