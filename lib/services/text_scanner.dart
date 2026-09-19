import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Raw text recognised from a photograph or PDF.
class RecognisedText {
  final List<String> lines;
  final double confidence;
  final String engine;

  const RecognisedText({
    required this.lines,
    required this.confidence,
    required this.engine,
  });
}

class TextScanException implements Exception {
  final String message;
  const TextScanException(this.message);
  @override
  String toString() => message;
}

/// Bridge to the platform text recogniser.
///
/// On iOS this is Apple's Vision framework, called through a method channel in
/// `ios/Runner/TextScanner.swift`. Vision ships with the OS, so the app carries
/// no OCR dependency, the work happens entirely on the device, and a learner's
/// results are never sent anywhere to be read.
class TextScanner {
  TextScanner._();
  static final instance = TextScanner._();

  static const _channel = MethodChannel('khetha.dhet/text_scanner');

  /// True when the running platform has a recogniser wired up. Android would
  /// need its own implementation; the app degrades to manual entry rather than
  /// hiding the feature.
  bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  Future<RecognisedText> recognise(String path) async {
    if (!isSupported) {
      throw const TextScanException(
        'Scanning is available on iOS in this build. You can still enter your results by hand.',
      );
    }

    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'recognise',
        {'path': path},
      );
      if (raw == null) {
        throw const TextScanException('Nothing came back from the scanner.');
      }

      final lines = (raw['lines'] as List?)?.whereType<String>().toList() ?? [];
      final confidence = raw['confidence'];
      final engine = raw['engine'];

      return RecognisedText(
        lines: lines,
        confidence: confidence is num ? confidence.toDouble() : 0,
        engine: engine is String ? engine : 'On-device',
      );
    } on PlatformException catch (e) {
      throw TextScanException(
        e.message ?? 'That file could not be read. Try a clearer photo.',
      );
    }
  }
}
