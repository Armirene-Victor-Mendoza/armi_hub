import 'package:armi_hub/features/app_context/domain/entities/branch_office.dart';

abstract class BranchOfficeRepository {
  Future<List<BranchOffice>> getBranchOffices({required int businessId});
}
