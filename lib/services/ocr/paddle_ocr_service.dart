import 'dart:io';
import 'package:paddle_ocr_flutter/paddle_ocr_flutter.dart';
import '../../data/models/scan_event.dart';
import '../logging/event_logger.dart';

class PaddleOcrService {
  final EventLogger _logger = EventLogger();
  late final PaddleOCR _paddleOCR;
  bool _isInitialized = false;

  /// Initialize PaddleOCR with Persian/Arabic support
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrEngineInit',
        message: 'Initializing PaddleOCR engine...',
      );

      _paddleOCR = PaddleOCR();
      
      // Initialize with models that support Persian/Arabic
      // PaddleOCR PP-OCRv5 has excellent multilingual support
      await _paddleOCR.init(
        threadNum: 4, // Use multiple threads for speed
        modelDir: 'models', // Default bundled model directory
        labelPath: 'labels/ppocr_keys_v1.txt', // Default label path
      );

      _isInitialized = true;

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrEngineReady',
        message: 'PaddleOCR initialized successfully with multilingual support.',
      );
    } catch (e) {
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'OCR',
        eventName: 'OcrEngineFailed',
        message: 'Failed to initialize PaddleOCR.',
        technicalDetails: e.toString(),
      );
      rethrow;
    }
  }

  /// Takes an image file and extracts text with PaddleOCR
  /// Supports Persian, Arabic, English, and many other languages
  Future<String?> processImage(File imageFile) async {
    try {
      // Ensure initialization
      if (!_isInitialized) {
        await initialize();
      }

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrStarted',
        message: 'Starting PaddleOCR text recognition...',
      );

      // Run OCR using the recognize method with file path
      final List<OcrResult> results = await _paddleOCR.recognize(imageFile.path);

      // Extract text from results while preserving structure
      StringBuffer structuredText = StringBuffer();

      if (results.isEmpty) {
        await _logger.logEvent(
          severity: LogSeverity.warning,
          module: 'OCR',
          eventName: 'OcrCompleted',
          message: 'PaddleOCR found no text in image.',
        );
        return '';
      }

      // Group results by line/y-coordinate to preserve paragraph structure
      Map<int, List<String>> linesByY = {};

      for (var result in results) {
        // Get approximate Y position from bounding box
        // PaddleOCR returns 'points' as List<OcrPoint> for bounding box
        final points = result.points;
        if (points.isEmpty) continue;
        
        // OcrPoint has x and y properties directly
        final yPosition = ((points[0].y + points[2].y) / 2).round();
        
        // Group text blocks that are on the same line (within 10 pixels)
        int groupedY = (yPosition / 10).round() * 10;
        
        if (!linesByY.containsKey(groupedY)) {
          linesByY[groupedY] = [];
        }
        linesByY[groupedY]!.add(result.text);
      }

      // Sort by Y position (top to bottom) and combine texts on same line
      var sortedYs = linesByY.keys.toList()..sort();

      for (var y in sortedYs) {
        // Sort texts on the same line by X position (left to right)
        // For simplicity, we join them with space
        // In production, you could sort by result.box coordinates
        String lineText = linesByY[y]!.join(' ');
        structuredText.writeln(lineText);
      }

      final finalText = structuredText.toString().trim();

      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'OCR',
        eventName: 'OcrCompleted',
        message: 'Successfully extracted ${finalText.length} characters with PaddleOCR.',
      );

      return finalText;

    } catch (e) {
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'OCR',
        eventName: 'OcrFailed',
        message: 'Failed to process image with PaddleOCR.',
        technicalDetails: e.toString(),
      );
      return null;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _paddleOCR.dispose();
      _isInitialized = false;
    }
  }
}
