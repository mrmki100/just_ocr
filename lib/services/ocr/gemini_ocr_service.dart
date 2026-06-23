import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/error/app_error.dart';
import '../../data/models/scan_event.dart';
import '../logging/event_logger.dart';

class GeminiOcrService {
  final EventLogger _logger = EventLogger();
  
  static const _apiKey = 'AQ.Ab8RN6Lv98HNQQb2cflqvpB42UWZwrwT7OT-RTV9J4EfjCQNEA';

  /// Processes an image file and extracts text using Gemini API.
  /// 
  /// Throws [GeminiApiException] for API-specific errors.
  /// Throws [OcrException] for general OCR processing errors.
  /// Throws [FileOperationException] for file I/O errors.
  Future<String?> processImage(File imageFile) async {
    try {
      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'GeminiOCR',
        eventName: 'CloudOcrStarted',
        message: 'Uploading page to Gemini for Persian OCR...',
      );

      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw FileOperationException(
          message: 'Image file does not exist.',
          operationType: FileOperationType.fileNotFound,
        );
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      final Uint8List imageBytes;
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        throw FileOperationException(
          message: 'Failed to read image file.',
          technicalDetails: e.toString(),
          operationType: FileOperationType.readFailed,
        );
      }

      // Validate image is not empty
      if (imageBytes.isEmpty) {
        throw OcrException(
          message: 'Image file is empty.',
          failureType: OcrFailureType.invalidImageFormat,
        );
      }
      
      final prompt = TextPart(
        'You are a highly accurate OCR document scanner. Extract all the text from this image exactly as it appears. '
        'Preserve the paragraph structure and line breaks perfectly. If the text is in Persian (Farsi), '
        'extract it in Persian without translating or summarizing it.'
      );
      final imagePart = DataPart('image/jpeg', imageBytes);

      final Content response;
      try {
        response = await model.generateContent([
          Content.multi([prompt, imagePart])
        ]);
      } on ClientException catch (e) {
        // Network-related API errors
        final apiError = GeminiApiException.fromException(e);
        await _logger.logEvent(
          severity: LogSeverity.error,
          module: 'GeminiOCR',
          eventName: 'CloudOcrFailed',
          message: 'Gemini API network error.',
          technicalDetails: e.toString(),
        );
        throw apiError;
      } on ApiException catch (e) {
        // API-specific errors (auth, quota, etc.)
        final apiError = GeminiApiException.fromException(e);
        await _logger.logEvent(
          severity: LogSeverity.error,
          module: 'GeminiOCR',
          eventName: 'CloudOcrFailed',
          message: 'Gemini API error.',
          technicalDetails: e.toString(),
        );
        throw apiError;
      } catch (e) {
        // Unexpected errors during API call
        final apiError = GeminiApiException.fromException(e);
        await _logger.logEvent(
          severity: LogSeverity.error,
          module: 'GeminiOCR',
          eventName: 'CloudOcrFailed',
          message: 'Unexpected Gemini API error.',
          technicalDetails: e.toString(),
        );
        throw apiError;
      }

      // Validate response contains text
      final String? extractedText = response.text;
      if (extractedText == null || extractedText.trim().isEmpty) {
        throw OcrException(
          message: 'No text detected in the image by Gemini.',
          failureType: OcrFailureType.noTextDetected,
        );
      }

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'GeminiOCR',
        eventName: 'CloudOcrCompleted',
        message: 'Successfully extracted ${extractedText.length} characters via Gemini.',
      );

      return extractedText;
    } on AppError {
      // Re-throw our structured errors as-is
      rethrow;
    } catch (e, stackTrace) {
      // Catch-all for any unexpected errors
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'GeminiOCR',
        eventName: 'CloudOcrFailed',
        message: 'Critical unexpected error in Gemini OCR.',
        technicalDetails: '$e\n$stackTrace',
      );
      throw OcrException(
        message: 'An unexpected error occurred during OCR processing.',
        technicalDetails: e.toString(),
        failureType: OcrFailureType.unknown,
      );
    }
  }

  void dispose() {}
}