// lib/services/tts/tts_service.dart
// Abstract Text-to-Speech service interface
// 
// Provides accessibility-focused TTS functionality:
// - Play/pause/resume controls
// - Speed and pitch adjustment
// - Sentence-level navigation
// - Background playback support

import 'dart:async';

/// Callback for TTS state changes
typedef TTSStateCallback = void Function(TTSState state);

/// Current state of the TTS engine
enum TTSState {
  idle,       // Not playing anything
  playing,    // Currently speaking
  paused,     // Playback paused
  stopped,    // Playback stopped
  error       // Error occurred
}

abstract class TTSService {
  /// Initialize the TTS engine
  Future<void> initialize();
  
  /// Speak the given text
  Future<void> speak(String text);
  
  /// Pause current playback
  Future<void> pause();
  
  /// Resume paused playback
  Future<void> resume();
  
  /// Stop playback completely
  Future<void> stop();
  
  /// Check if currently speaking
  bool get isSpeaking;
  
  /// Check if playback is paused
  bool get isPaused;
  
  /// Get current TTS state
  TTSState get currentState;
  
  /// Set speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate);
  
  /// Set speech pitch (0.0 to 2.0, default 1.0)
  Future<void> setPitch(double pitch);
  
  /// Set speech volume (0.0 to 1.0, default 1.0)
  Future<void> setVolume(double volume);
  
  /// Get available voices
  Future<List<TTSVoice>> getAvailableVoices();
  
  /// Set the voice to use
  Future<void> setVoice(TTSVoice voice);
  
  /// Split text into sentences for better navigation
  List<String> splitIntoSentences(String text);
  
  /// Dispose resources
  void dispose();
}

/// Represents a TTS voice option
class TTSVoice {
  final String name;
  final String locale;
  final String? quality;
  
  TTSVoice({
    required this.name,
    required this.locale,
    this.quality,
  });
  
  @override
  String toString() => '$name ($locale)';
}
