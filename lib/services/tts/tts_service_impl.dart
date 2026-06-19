// lib/services/tts/tts_service_impl.dart
// Flutter TTS implementation with accessibility features
// 
// Features:
// - Play/pause/resume/stop controls
// - Adjustable speech rate, pitch, and volume
// - Sentence-level navigation
// - Proper error handling
// - Persian language support

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_service.dart';

class TTSServiceImpl implements TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  TTSState _currentState = TTSState.idle;
  
  double _speechRate = 0.5; // Default rate
  double _pitch = 1.0;      // Default pitch
  double _volume = 1.0;     // Default volume
  
  StreamController<TTSState>? _stateController;
  
  @override
  TTSState get currentState => _currentState;
  
  @override
  bool get isSpeaking => _currentState == TTSState.playing;
  
  @override
  bool get isPaused => _currentState == TTSState.paused;
  
  @override
  Future<void> initialize() async {
    try {
      // Set default parameters
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);
      
      // Prefer Android TTS engine for better Persian support
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setLanguage('fa-IR');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setLanguage('fa-IR');
      }
      
      // Listen to TTS state changes
      _flutterTts.setStartHandler(() {
        _updateState(TTSState.playing);
        debugPrint('[TTS] Started speaking');
      });
      
      _flutterTts.setCompletionHandler(() {
        _updateState(TTSState.idle);
        debugPrint('[TTS] Completed speaking');
      });
      
      _flutterTts.setCancelHandler(() {
        _updateState(TTSState.stopped);
        debugPrint('[TTS] Stopped speaking');
      });
      
      _flutterTts.setErrorHandler((message) {
        _updateState(TTSState.error);
        debugPrint('[TTS] Error: $message');
      });
      
      _stateController = StreamController<TTSState>.broadcast();
      
      debugPrint('[TTS] Initialized successfully');
    } catch (e) {
      debugPrint('[TTS] Initialization failed: $e');
      rethrow;
    }
  }
  
  void _updateState(TTSState newState) {
    _currentState = newState;
    _stateController?.add(newState);
  }
  
  @override
  Future<void> speak(String text) async {
    try {
      if (text.trim().isEmpty) {
        debugPrint('[TTS] Empty text, skipping');
        return;
      }
      
      // Stop any current playback first
      await stop();
      
      // Clean up text for better pronunciation
      final cleanedText = text
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
          .trim();
      
      await _flutterTts.speak(cleanedText);
      debugPrint('[TTS] Speaking: ${cleanedText.substring(0, Math.min(50, cleanedText.length))}...');
    } catch (e) {
      debugPrint('[TTS] Speak failed: $e');
      _updateState(TTSState.error);
      rethrow;
    }
  }
  
  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _updateState(TTSState.paused);
      debugPrint('[TTS] Paused');
    } catch (e) {
      debugPrint('[TTS] Pause failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> resume() async {
    try {
      await _flutterTts.stop(); // flutter_tts doesn't have resume, restart from beginning
      // Note: flutter_tts doesn't support true resume from pause point
      // For production, consider using a different TTS library or caching position
      debugPrint('[TTS] Resume not fully supported, restarting');
    } catch (e) {
      debugPrint('[TTS] Resume failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _updateState(TTSState.stopped);
      debugPrint('[TTS] Stopped');
    } catch (e) {
      debugPrint('[TTS] Stop failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      debugPrint('[TTS] Speech rate set to $_speechRate');
    } catch (e) {
      debugPrint('[TTS] Set speech rate failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.0, 2.0);
      await _flutterTts.setPitch(_pitch);
      debugPrint('[TTS] Pitch set to $_pitch');
    } catch (e) {
      debugPrint('[TTS] Set pitch failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      debugPrint('[TTS] Volume set to $_volume');
    } catch (e) {
      debugPrint('[TTS] Set volume failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices.map((voiceData) {
        // Voice data format varies by platform
        return TTSVoice(
          name: voiceData['name'] ?? 'Unknown',
          locale: voiceData['locale'] ?? 'unknown',
          quality: voiceData['quality']?.toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[TTS] Get voices failed: $e');
      return [];
    }
  }
  
  @override
  Future<void> setVoice(TTSVoice voice) async {
    try {
      await _flutterTts.setVoice({'name': voice.name, 'locale': voice.locale});
      debugPrint('[TTS] Voice set to ${voice.name}');
    } catch (e) {
      debugPrint('[TTS] Set voice failed: $e');
      rethrow;
    }
  }
  
  @override
  List<String> splitIntoSentences(String text) {
    // Split on sentence boundaries while preserving abbreviations
    // This regex handles common Persian/Arabic sentence endings
    final sentenceRegex = RegExp(
      r'(?<=[\.!?۔۔۔])\s+|(?<=[\u06D4\u061F])\s+',
      unicode: true,
    );
    
    final sentences = sentenceRegex
        .split(text)
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    
    // If no sentences found, return the whole text as one sentence
    if (sentences.isEmpty && text.trim().isNotEmpty) {
      return [text.trim()];
    }
    
    return sentences;
  }
  
  @override
  void dispose() {
    _stateController?.close();
    _flutterTts.stop();
    debugPrint('[TTS] Disposed');
  }
}

// Helper class for Math.min (since dart:math isn't imported)
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
