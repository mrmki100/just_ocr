import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/scan_event.dart';
import '../logging/event_logger.dart';

class GeminiOcrService {
  final EventLogger _logger = EventLogger();
  
  static const _apiKey = 'AQ.Ab8RN6Lv98HNQQb2cflqvpB42UWZwrwT7OT-RTV9J4EfjCQNEA';

  Future<String?> processImage(File imageFile) async {
    try {
      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'GeminiOCR',
        eventName: 'CloudOcrStarted',
        message: 'Uploading page to Gemini for Persian OCR...',
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = TextPart(
        'You are a highly accurate OCR document scanner. Extract all the text from this image exactly as it appears. '
        'Preserve the paragraph structure and line breaks perfectly. If the text is in Persian (Farsi), '
        'extract it in Persian without translating or summarizing it.'
      );
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'GeminiOCR',
        eventName: 'CloudOcrCompleted',
        message: 'Successfully extracted Persian text via Cloud Vision.',
      );

      return response.text;
    } catch (e) {
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'GeminiOCR',
        eventName: 'CloudOcrFailed',
        message: 'Gemini OCR failed.',
        technicalDetails: e.toString(),
      );
      // THIS IS THE FIX: Return the exact error string so the UI can show it!
      return "\n\n❌ GEMINI ERROR:\n${e.toString()}\n\n";
    }
  }

  void dispose() {}
}