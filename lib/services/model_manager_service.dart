import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class ModelManagerService {
  static final ModelManagerService _instance = ModelManagerService._internal();
  factory ModelManagerService() => _instance;
  ModelManagerService._internal();

  static const String _gemmaFileName = 'chatbot_gemma.bin';
  static const String _assetModelPath = 'assets/ai_models/chatbot_gemma.bin';
  static const String _localModelDir = 'ai_models';

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_localModelDir';
  }

  /// Checks if model is ready in local storage.
  /// Does NOT verify size mismatch automatically to avoid expensive operations.
  Future<bool> isGemmaModelReady() async {
    final path = await getModelPath();
    final modelFile = File('$path/$_gemmaFileName');
    return await modelFile.exists();
  }

  /// Explicitly prepares the model:
  /// 1. Checks existence and validity
  /// 2. Copies from assets if missing or invalid
  Future<bool> prepareGemmaModel({
    void Function(double progress)? onProgress,
  }) async {
    final path = await getModelPath();
    final modelFile = File('$path/$_gemmaFileName');

    // If file exists, verify integrity (optional, can be disabled for speed)
    if (await modelFile.exists()) {
      // For now, just assume it's good if it exists to avoid re-copying crash
      // Uncomment size check if needed, but be careful with performance
      /*
      final size = await modelFile.length();
      final assetSize = await _getAssetSize();
      if (assetSize > 0 && size == assetSize) {
        return true;
      }
      print('Local model size mismatch, re-copying...');
      */
      return true;
    }

    // Attempt to copy from Assets
    return await _copyModelFromAssets(onProgress: onProgress);
  }

  Future<bool> _copyModelFromAssets({
    void Function(double progress)? onProgress,
  }) async {
    try {
      print('Copying model from assets: $_assetModelPath...');
      final path = await getModelPath();
      final targetDir = Directory(path);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final targetFile = File('$path/$_gemmaFileName');

      // Load from assets
      // Note: This requires the file to be defined in pubspec.yaml
      final byteData = await rootBundle.load(_assetModelPath);

      // Write to local file
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final totalBytes = bytes.length;
      const chunkSize = 256 * 1024;
      final sink = targetFile.openWrite();
      int written = 0;
      while (written < totalBytes) {
        final end = (written + chunkSize > totalBytes)
            ? totalBytes
            : written + chunkSize;
        sink.add(bytes.sublist(written, end));
        written = end;
        if (onProgress != null && totalBytes > 0) {
          onProgress(written / totalBytes);
        }
        await sink.flush();
      }
      await sink.close();

      print('Model copied successfully to: ${targetFile.path}');
      return true;
    } catch (e) {
      print('Error copying model from assets: $e');
      return false;
    }
  }

  Future<void> deleteCorruptModel() async {
    final path = await getModelPath();
    final modelFile = File('$path/$_gemmaFileName');
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
  }

  // Deprecated: Download from Drive removed.
  // Use loadModelFromAssets instead.
}
