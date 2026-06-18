import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../data/models/scan_event.dart';
import '../logging/event_logger.dart';

class MLKitService {
  final EventLogger _logger = EventLogger();
  
  // Initialize the text recognizer for standard characters
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Takes an image file and extracts text while preserving paragraph structure
  Future<String?> processImage(File imageFile) async {
    try {
      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrStarted',
        message: 'Starting high-fidelity local text recognition...',
      );

      final inputImage = InputImage.fromFile(imageFile);
      
      // Command ML Kit to analyze the image
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

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

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrCompleted',
        message: 'Successfully extracted ${finalText.length} characters with layout preservation.',
      );

      return finalText;

    } catch (e) {
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'OCR',
        eventName: 'OcrFailed',
        message: 'Failed to process image with ML Kit.',
        technicalDetails: e.toString(),
      );
      return null;
    }
  }

  /// Always close the recognizer to prevent memory leaks
  void dispose() {
    _textRecognizer.close();
  }
}