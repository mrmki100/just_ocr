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
      // PaddleOCR PP-OCRv4 has excellent multilingual support
      await _paddleOCR.init(
        detModelPath: null, // Use default bundled model
        recModelPath: null, // Use default bundled model
        clsModelPath: null, // Use default classification model
        useGpu: false, // Use CPU for mobile compatibility
        threadNum: 4, // Use multiple threads for speed
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

      // Convert File to Uint8List for PaddleOCR
      final bytes = await imageFile.readAsBytes();

      // Run OCR
      final List<OcrResult> results = await _paddleOCR.predictImage(
        imageData: bytes,
        isAsset: false,
      );

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
        final yPosition = (result.box[0][1] + result.box[2][1]) ~/ 2;
        
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
  void dispose() {
    if (_isInitialized) {
      _paddleOCR.dispose();
      _isInitialized = false;
    }
  }
}
