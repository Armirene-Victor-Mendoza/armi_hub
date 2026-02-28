import 'dart:io';

abstract class ImageOptimizerRepository {
  Future<File> optimizeForUpload(File image);
}
