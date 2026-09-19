import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads text aloud using the phone's own speech engine.
///
/// Runs entirely on the device: no network, and nothing is sent anywhere. The
/// on/off switch and reading speed are stored with the other preferences.
///
/// Career and qualification records are in English whatever the interface
/// language is, so speech always uses an English voice (South African when the
/// phone has one).
class SpeechService extends ChangeNotifier {
  SpeechService._();
  static final instance = SpeechService._();

  static const _enabledKey = 'ttsEnabled';
  static const _rateKey = 'ttsRate';

  static const minRate = 0.25;
  static const maxRate = 0.75;

  final _tts = FlutterTts();
  SharedPreferences? _prefs;
  bool _ready = false;
  bool _enabled = true;
  double _rate = 0.5;
  String? _speakingId;

  bool get enabled => _enabled;
  double get rate => _rate;
  bool isSpeaking(String id) => _speakingId == id;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _rate = (prefs.getDouble(_rateKey) ?? 0.5).clamp(minRate, maxRate);
    try {
      _tts.setCompletionHandler(_finished);
      _tts.setErrorHandler((_) => _finished());
      for (final locale in const ['en-ZA', 'en-GB', 'en-US']) {
        final ok = await _tts.isLanguageAvailable(locale);
        if (ok == true || ok == 1) {
          await _tts.setLanguage(locale);
          break;
        }
      }
      await _tts.setSpeechRate(_rate);
      _ready = true;
    } catch (e) {
      // No speech engine on this device: the Listen buttons simply do nothing.
      debugPrint('Speech unavailable: $e');
    }
  }

  void _finished() {
    if (_speakingId == null) return;
    _speakingId = null;
    notifyListeners();
  }

  /// Speaks [text]. Calling it again for the same [id] stops instead.
  Future<void> speak(String id, String text) async {
    if (!_ready || !_enabled) return;
    if (_speakingId == id) {
      await stop();
      return;
    }
    await _tts.stop();
    _speakingId = id;
    notifyListeners();
    try {
      await _tts.speak(text);
    } catch (_) {
      _finished();
    }
  }

  Future<void> stop() async {
    if (_ready) await _tts.stop();
    if (_speakingId != null) {
      _speakingId = null;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs?.setBool(_enabledKey, value);
    if (!value) await stop();
    notifyListeners();
  }

  Future<void> setRate(double value) async {
    _rate = value.clamp(minRate, maxRate);
    await _prefs?.setDouble(_rateKey, _rate);
    if (_ready) await _tts.setSpeechRate(_rate);
    notifyListeners();
  }

  /// A short sample so the learner can judge the speed.
  Future<void> sample() =>
      speak('sample', 'This is how Khetha Go will read to you.');
}
