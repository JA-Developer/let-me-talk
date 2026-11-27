import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/pictograma.dart';

/// Servicio de síntesis de voz en español para reproducir pictogramas y frases.
class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _isSpeaking = false;
  int? _activeWordIndex;
  double _speechRate = 0.48;
  double _pitch = 1.0;

  List<(int, int)> _currentRanges = const [];

  bool get isSpeaking => _isSpeaking;
  int? get activeWordIndex => _activeWordIndex;
  double get speechRate => _speechRate;
  double get pitch => _pitch;

  Future<void> init({double speechRate = 0.48, double pitch = 1.0}) async {
    _speechRate = speechRate;
    _pitch = pitch;
    if (_initialized) {
      await updateVoiceSettings(speechRate: speechRate, pitch: pitch);
      return;
    }

    try {
      await _configureLanguage();
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _activeWordIndex = null;
        _currentRanges = const [];
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _activeWordIndex = null;
        _currentRanges = const [];
        notifyListeners();
      });

      _tts.setErrorHandler((_) {
        _isSpeaking = false;
        _activeWordIndex = null;
        _currentRanges = const [];
        notifyListeners();
      });

      _tts.setProgressHandler((String text, int start, int end, String word) {
        if (_currentRanges.isEmpty) return;
        for (var i = 0; i < _currentRanges.length; i++) {
          final (rStart, rEnd) = _currentRanges[i];
          if (start >= rStart && start < rEnd) {
            if (_activeWordIndex != i) {
              _activeWordIndex = i;
              notifyListeners();
            }
            break;
          }
        }
      });

      _initialized = true;
    } on MissingPluginException {
      _initialized = false;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _configureLanguage() async {
    const preferredLocales = ['es-ES', 'es-MX', 'es-US', 'es'];
    try {
      final available = await _tts.getLanguages;
      if (available is List) {
        final normalized = available.map((e) => e.toString()).toList();
        for (final locale in preferredLocales) {
          final match = normalized.where(
            (lang) => lang.toLowerCase() == locale.toLowerCase(),
          );
          if (match.isNotEmpty) {
            await _tts.setLanguage(match.first);
            return;
          }
        }
        final anySpanish = normalized.where(
          (lang) => lang.toLowerCase().startsWith('es'),
        );
        if (anySpanish.isNotEmpty) {
          await _tts.setLanguage(anySpanish.first);
          return;
        }
      }
    } catch (_) {}
    await _tts.setLanguage('es-ES');
  }

  Future<void> updateVoiceSettings({
    required double speechRate,
    required double pitch,
  }) async {
    _speechRate = speechRate;
    _pitch = pitch;
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
    } on MissingPluginException {
      // Ignorado en pruebas de widgets.
    } catch (_) {}
  }

  Future<void> speakText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!_initialized) {
      await init(speechRate: _speechRate, pitch: _pitch);
    }
    try {
      _currentRanges = const [];
      _activeWordIndex = null;
      await _tts.stop();
      await _tts.speak(trimmed);
    } on MissingPluginException {
      // Ignorado en pruebas.
    } catch (_) {}
  }

  Future<void> speakSentence(List<Pictograma> pictogramas) async {
    if (pictogramas.isEmpty) return;
    if (!_initialized) {
      await init(speechRate: _speechRate, pitch: _pitch);
    }

    final buffer = StringBuffer();
    final ranges = <(int, int)>[];

    for (var i = 0; i < pictogramas.length; i++) {
      if (i > 0) buffer.write(' ');
      final start = buffer.length;
      final word = pictogramas[i].textoVoz.trim();
      buffer.write(word);
      ranges.add((start, buffer.length));
    }

    _currentRanges = ranges;
    _activeWordIndex = 0;
    _isSpeaking = true;
    notifyListeners();

    try {
      await _tts.stop();
      await _tts.speak(buffer.toString());
    } on MissingPluginException {
      _isSpeaking = false;
      _activeWordIndex = null;
      notifyListeners();
    } catch (_) {
      _isSpeaking = false;
      _activeWordIndex = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    _activeWordIndex = null;
    _currentRanges = const [];
    notifyListeners();
    try {
      await _tts.stop();
    } on MissingPluginException {
      // Ignorado en pruebas.
    } catch (_) {}
  }
}
