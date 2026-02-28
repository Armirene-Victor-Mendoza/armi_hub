import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:armi_hub/core/utils/concurrency/limiters.dart';
import 'package:armi_hub/features/receipt_capture/domain/repositories/image_optimizer_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class ImageOptimizerRepositoryImpl implements ImageOptimizerRepository {
  static const int _smallThreshold = 1 * 1024 * 1024; // 1MB
  static const int _largeThreshold = 5 * 1024 * 1024; // 5MB
  static final _random = Random();

  final bool enableWebP;

  bool _cleanupRunning = false;

  ImageOptimizerRepositoryImpl({this.enableWebP = false});

  @override
  Future<File> optimizeForUpload(File originalImage) async {
    if (!await originalImage.exists()) {
      throw Exception("Original image not found");
    }
    final fileSize = await originalImage.length();
    final strategy = await _resolveStrategy(originalImage, fileSize);

    if (_shouldSkipOptimization(fileSize, strategy)) {
      return originalImage;
    }

    final targetPath = _buildTargetPath(originalImage, strategy);
    final cachedFile = File(targetPath);

    if (await cachedFile.exists()) {
      return cachedFile;
    }

    return CoreLimiters.imageCompression.run(() async {
      final optimized = await _safeCompressWithFallback(originalImage, strategy, targetPath);

      if (_random.nextInt(5) == 0) {
        unawaited(_cleanupCache(originalImage.parent));
      }

      return optimized;
    });
  }

  Future<_CompressionStrategy> _resolveStrategy(File file, int fileSize) async {
    if (fileSize < 600 * 1024) {
      return _CompressionStrategy(quality: 85, maxWidth: 1920, maxHeight: 1920, format: _resolveFormat());
    }
    final mp = await _getMegaPixels(file);

    //  Forzar resize si excede megapíxeles
    if (mp > 6) {
      return _CompressionStrategy(quality: 70, maxWidth: 1600, maxHeight: 1600, format: _resolveFormat());
    }

    // fallback por tamaño
    if (fileSize < _smallThreshold) {
      return _CompressionStrategy(quality: 85, maxWidth: 1920, maxHeight: 1920, format: _resolveFormat());
    }

    if (fileSize < _largeThreshold) {
      return _CompressionStrategy(quality: 75, maxWidth: 1600, maxHeight: 1600, format: _resolveFormat());
    }

    return _CompressionStrategy(quality: 60, maxWidth: 1280, maxHeight: 1280, format: _resolveFormat());
  }

  CompressFormat _resolveFormat() {
    return enableWebP ? CompressFormat.webp : CompressFormat.jpeg;
  }

  bool _shouldSkipOptimization(int fileSize, _CompressionStrategy strategy) {
    // Evita recomprimir imágenes ya livianas
    return fileSize < 400 * 1024; // 400KB
  }

  String _buildTargetPath(File file, _CompressionStrategy strategy) {
    final extension = strategy.format == CompressFormat.webp ? "webp" : "jpg";

    final dir = file.parent.path;
    final name = file.uri.pathSegments.last;

    return "$dir/${name}_q${strategy.quality}_optimized.$extension";
  }

  Future<double> _getMegaPixels(File file) async {
    final bytes = await file.readAsBytes();

    final decoded = img.decodeImage(bytes);
    bytes.clear();

    if (decoded == null) return 0;

    return (decoded.width * decoded.height) / 1000000;
  }

  Future<File> _safeCompressWithFallback(File originalImage, _CompressionStrategy strategy, String targetPath) async {
    try {
      return await compute(
        _compressInIsolate,
        _IsolateParams(
          inputPath: originalImage.path,
          outputPath: targetPath,
          quality: strategy.quality,
          maxWidth: strategy.maxWidth,
          maxHeight: strategy.maxHeight,
          format: strategy.format,
        ),
      );
    } catch (_) {
      // fallback
      final result = await FlutterImageCompress.compressAndGetFile(
        originalImage.path,
        targetPath,
        quality: strategy.quality,
        minWidth: strategy.maxWidth,
        minHeight: strategy.maxHeight,
        format: strategy.format,
        keepExif: false,
        autoCorrectionAngle: true,
      );

      if (result == null) throw Exception("Compression failed");

      return File(result.path);
    }
  }

  Future<void> _cleanupCache(Directory dir) async {
    if (_cleanupRunning) return;
    _cleanupRunning = true;

    try {
      const maxCacheSizeMB = 150;
      const maxAgeDays = 3;

      final files = await dir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .where((f) => f.path.contains("_optimized"))
          .toList();

      int totalSize = 0;
      final now = DateTime.now();

      for (final file in files) {
        final stat = await file.stat();

        final age = now.difference(stat.modified).inDays;

        if (age > maxAgeDays) {
          try {
            await file.delete();
          } catch (_) {}
          continue;
        }

        totalSize += stat.size;
      }

      if (totalSize > maxCacheSizeMB * 1024 * 1024) {
        // elimina los más viejos
        final sorted = files.toList()..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        for (final file in sorted) {
          try {
            await file.delete();
          } catch (_) {}
          totalSize -= await file.length();

          if (totalSize < maxCacheSizeMB * 1024 * 1024) break;
        }
      }
    } finally {
      _cleanupRunning = false;
    }
  }
}

class _CompressionStrategy {
  final int quality;
  final int maxWidth;
  final int maxHeight;
  final CompressFormat format;

  _CompressionStrategy({required this.quality, required this.maxWidth, required this.maxHeight, required this.format});
}

class _IsolateParams {
  final String inputPath;
  final String outputPath;
  final int quality;
  final int maxWidth;
  final int maxHeight;
  final CompressFormat format;

  _IsolateParams({
    required this.inputPath,
    required this.outputPath,
    required this.quality,
    required this.maxWidth,
    required this.maxHeight,
    required this.format,
  });
}

Future<File> _compressInIsolate(_IsolateParams params) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    params.inputPath,
    params.outputPath,
    quality: params.quality,
    minWidth: params.maxWidth,
    minHeight: params.maxHeight,
    format: params.format,
    keepExif: false,
    autoCorrectionAngle: true,
  );

  if (result == null) {
    throw Exception("Compression failed");
  }

  return File(result.path);
}
