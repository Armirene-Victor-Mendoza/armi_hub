import 'dart:convert';
import 'dart:io';

import 'package:armi_hub/core/network/network.dart';
import 'package:armi_hub/features/order_creation/domain/entities/upload_image_result.dart';
import 'package:mime/mime.dart';

class ImageUploadRemoteDataSource {
  const ImageUploadRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String _uploadUrl = 'https://upload-tickets-kokorico-681515725483.us-central1.run.app';

  Future<UploadImageResult> uploadReceiptImage({required String imagePath}) async {
    try {
      final response = await _apiClient.postMultipartAbsoluteUrl(_uploadUrl, fileFieldName: 'file', filePath: imagePath);

      if (!response.isSuccess) {
        return UploadImageResult(
          success: false,
          statusCode: response.statusCode,
          responseBodyRaw: response.bodyRaw,
          errorMessage: 'El upload respondio con codigo ${response.statusCode}.',
        );
      }

      final dynamic decoded = jsonDecode(response.bodyRaw);
      if (decoded is! Map<String, dynamic>) {
        return UploadImageResult(
          success: false,
          statusCode: response.statusCode,
          responseBodyRaw: response.bodyRaw,
          errorMessage: 'Respuesta invalida del upload.',
        );
      }

      final urlImage = (decoded['signedUrl'] as String?)?.trim();
      if (urlImage == null || urlImage.isEmpty) {
        return UploadImageResult(
          success: false,
          statusCode: response.statusCode,
          responseBodyRaw: response.bodyRaw,
          errorMessage: 'El upload no retorno signedUrl.',
        );
      }

      return UploadImageResult(
        success: true,
        statusCode: response.statusCode,
        responseBodyRaw: response.bodyRaw,
        urlImage: urlImage,
      );
    } on ApiException catch (error) {
      return UploadImageResult(success: false, statusCode: null, responseBodyRaw: '', errorMessage: error.message);
    } on FormatException {
      return const UploadImageResult(
        success: false,
        statusCode: null,
        responseBodyRaw: '',
        errorMessage: 'El upload retorno un JSON invalido.',
      );
    } catch (error) {
      return UploadImageResult(
        success: false,
        statusCode: null,
        responseBodyRaw: '',
        errorMessage: 'Error inesperado subiendo imagen: $error',
      );
    }
  }
}
