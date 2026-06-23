import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/error/app_error.dart';
import '../../data/models/scan_event.dart';
import '../logging/event_logger.dart';

class MLKitService {
  final EventLogger _logger = EventLogger();
  
  // Initialize the text recognizer for standard characters
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Takes an image file and extracts text while preserving paragraph structure.
  /// 
  /// Throws [MLKitException] for ML Kit processing errors.
  /// Throws [FileOperationException] for file I/O errors.
  /// Throws [OcrException] when no text is detected.
  Future<String?> processImage(File imageFile) async {
    try {
      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrStarted',
        message: 'Starting high-fidelity local text recognition...',
      );

      // Validate file exists
      if (!await imageFile.exists()) {
        throw FileOperationException(
          message: 'Image file does not exist.',
          operationType: FileOperationType.fileNotFound,
        );
      }

      InputImage inputImage;
      try {
        inputImage = InputImage.fromFile(imageFile);
      } catch (e) {
        throw FileOperationException(
          message: 'Failed to load image file for ML Kit.',
          technicalDetails: e.toString(),
          operationType: FileOperationType.readFailed,
        );
      }
      
      // Command ML Kit to analyze the image
      final RecognizedText recognizedText;
      try {
        recognizedText = await _textRecognizer.processImage(inputImage);
      } catch (e) {
        throw MLKitException.fromException(e);
      }

      // ---------------------------------------------------------
      // THE ACCURACY BOOST: Structural Extraction
      // Instead of dumping raw text, we rebuild the document 
      // block-by-block to preserve paragraphs and spacing.
      // ---------------------------------------------------------
      StringBuffer structuredText = StringBuffer();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Write each line exactly as it appears in the image
          structuredText.writeln(line.text);
        }
        // Add a blank line to visually separate paragraphs
        structuredText.writeln(); 
      }

      final finalText = structuredText.toString().trim();

      // Validate that text was actually extracted
      if (finalText.isEmpty) {
        throw OcrException(
          message: 'No text detected in the image by ML Kit.',
          failureType: OcrFailureType.noTextDetected,
        );
      }

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrCompleted',
        message: 'Successfully extracted ${finalText.length} characters with layout preservation.',
      );

      return finalText;

    } on AppError {
      // Re-throw our structured errors as-is
      rethrow;
    } catch (e, stackTrace) {
      // Catch-all for any unexpected errors
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'OCR',
        eventName: 'OcrFailed',
        message: 'Critical unexpected error in ML Kit OCR.',
        technicalDetails: '$e\n$stackTrace',
      );
      throw OcrException(
        message: 'An unexpected error occurred during ML Kit processing.',
        technicalDetails: e.toString(),
        failureType: OcrFailureType.unknown,
      );
    }
  }

  /// Always close the recognizer to prevent memory leaks
  void dispose() {
    _textRecognizer.close();
  }
}