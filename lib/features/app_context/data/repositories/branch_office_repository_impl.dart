import 'dart:convert';

import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/features/app_context/domain/entities/branch_office.dart';
import 'package:armi_hub/features/app_context/domain/repositories/branch_office_repository.dart';

class BranchOfficeRepositoryImpl implements BranchOfficeRepository {
  const BranchOfficeRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String _monitorBaseUrl = 'https://armi-business-monitor-dot-armirene-369418.uc.r.appspot.com';
  static const String _apiKey = '87efc80c-f21a-4e76-8a80-7eae5575720c';

  @override
  Future<List<BranchOffice>> getBranchOffices({required int businessId}) async {
    final url = '$_monitorBaseUrl/monitor/branchOffice/all/$businessId';

    final response = await _apiClient.getJsonFromAbsoluteUrl(
      url,
      extraHeaders: const <String, String>{
        'COUNTRY': 'COL',
        'armi-business-api-key': _apiKey,
      },
    );

    if (!response.isSuccess) {
      throw Exception('No se pudo cargar sucursales. HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.bodyRaw) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? <dynamic>[];

    return data
        .whereType<Map<String, dynamic>>()
        .map(BranchOffice.fromJson)
        .toList(growable: false);
  }
}
