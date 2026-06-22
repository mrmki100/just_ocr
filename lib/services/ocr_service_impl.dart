// lib/services/ocr_service_impl.dart
// Consolidated OCR service supporting PDF, EPUB, and images
// with proper progress reporting and error handling
// Updated to support dynamic model selection based on user preference
// Rate-limited to 1 request per 10 seconds to respect Gemini API RPM limits

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../features/reader/book_notifier.dart';

class OcrServiceImpl implements OcrService {
  // Gemini model for cloud OCR (better for Persian/Arabic)
  late GenerativeModel _geminiModel;
  final SharedPreferences _prefs;
  String _modelName;
  
  // Rate limiting: track last request time to enforce 10-second interval
  DateTime? _lastRequestTime;
  final Duration _requestInterval = AppConstants.geminiRequestInterval;

  OcrServiceImpl(this._prefs, {String? modelName}) : _modelName = modelName ?? AppConstants.defaultOcrModel {
    _initializeModel();
  }

  void _initializeModel() {
    // API key will be retrieved from SharedPreferences at runtime
    final apiKey = _prefs.getString('gemini_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      debugPrint('⚠️ WARNING: GEMINI_API_KEY not provided. Cloud OCR will fail.');
    }
    
    _geminiModel = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
    );
  }

  /// Update the model name and reinitialize the Gemini model
  void updateModel(String modelName) {
    _modelName = modelName;
    _initializeModel();
    debugPrint('[OcrServiceImpl] Model updated to: $_modelName');
  }

  /// Get the current model name
  String get currentModelName => _modelName;

  /// Enforce rate limiting by waiting until 10 seconds have passed since last request
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _requestInterval) {
        final remaining = _requestInterval - elapsed;
        debugPrint('[OcrServiceImpl] Rate limit: waiting ${remaining.inSeconds}s before next request');
        await Future.delayed(remaining);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  @override
  Future<List<String>> extractPages(
    File file, {
    required ProgressCallback onProgress,
  }) async {
    try {
      final String path = file.path.toLowerCase();
      final List<String> extractedPages = [];

      // Determine file type and process accordingly
      if (path.endsWith('.pdf')) {
        return await _processPdf(file, onProgress);
      } else if (path.endsWith('.epub')) {
        // EPUB support: extract text directly (no OCR needed for most EPUBs)
        return await _processEpub(file, onProgress);
      } else if (['.jpg', '.jpeg', '.png'].any((ext) => path.endsWith(ext))) {
        // Single image processing
        onProgress('در حال استخراج متن از تصویر...', null);
        final String text = await _processImage(file);
        return [text];
      } else {
        throw UnsupportedError(
          'فرمت فایل پشتیبانی نمی‌شود. فرمت‌های مجاز: PDF, EPUB, JPG, PNG',
        );
      }
    } catch (e) {
      debugPrint('[OcrServiceImpl] Error: $e');
      rethrow;
    }
  }

  /// Process PDF by rendering each page as image and running OCR
  /// Rate-limited to 1 request per 10 seconds to respect Gemini API RPM limits (5-10 RPM)
  Future<List<String>> _processPdf(
    File file,
    ProgressCallback onProgress,
  ) async {
    onProgress('در حال باز کردن فایل PDF...', null);
    
    final PdfDocument document = await PdfDocument.openFile(file.path);
    final int totalPages = document.pagesCount;
    
    // Limit to first 10 pages for performance (configurable)
    // In production, remove this limit or make it a user setting
    final int pagesToProcess = totalPages > 10 ? 10 : totalPages;
    
    final List<String> extractedPages = [];
    final Directory tempDir = await getTemporaryDirectory();

    try {
      for (int i = 1; i <= pagesToProcess; i++) {
        final double progress = i / pagesToProcess;
        
        onProgress(
          'در حال پردازش صفحه $i از $pagesToProcess...',
          progress * 0.5, // First 50% for rendering
        );

        // Render page to high-quality image
        final PdfPage page = await document.getPage(i);
        final PdfPageImage? pageImage = await page.render(
          width: (page.width * 2.0),
          height: (page.height * 2.0),
          format: PdfPageImageFormat.jpeg,
        );
        await page.close();

        if (pageImage == null) {
          extractedPages.add('⚠️ صفحه $i: تصویری دریافت نشد');
          continue;
        }

        // Save rendered page to temp file
        final File tempImageFile = File('${tempDir.path}/page_$i.jpg');
        await tempImageFile.writeAsBytes(pageImage.bytes);

        onProgress(
          'در حال استخراج متن از صفحه $i...',
          0.5 + (progress * 0.5), // Second 50% for OCR
        );

        // Run OCR on the page image using Gemini
        // Each page is rate-limited to 10 seconds between requests
        final String pageText = await _processImage(tempImageFile);

        extractedPages.add(pageText.isNotEmpty ? pageText : '⚠️ متنی در صفحه $i یافت نشد');
        
        // Cleanup temp file
        if (await tempImageFile.exists()) {
          await tempImageFile.delete();
        }
      }
    } finally {
      await document.close();
    }

    return extractedPages;
  }

  /// Process EPUB by extracting text directly from chapters
  Future<List<String>> _processEpub(
    File file,
    ProgressCallback onProgress,
  ) async {
    onProgress('در حال باز کردن فایل EPUB...', null);
    
    // Note: Full EPUB parsing requires epub_view package integration
    // For now, return a placeholder - implement full EPUB support in Phase 3
    await Future.delayed(const Duration(milliseconds: 500));
    onProgress('پشتیبانی از EPUB به زودی اضافه می‌شود...', 1.0);
    
    return ['پشتیبانی از فایل‌های EPUB در نسخه آینده اضافه خواهد شد.'];
  }

  /// Process single image with OCR using Gemini
  /// Rate-limited to 1 request per 10 seconds for Gemini API calls
  Future<String> _processImage(File imageFile) async {
    return await _geminiOcr(imageFile);
  }

  /// Cloud OCR using Gemini (best for Persian/Arabic)
  /// Enforces strict 10-second rate limiting between each API request
  /// to stay within RPM limits (5-10 requests per minute depending on model)
  Future<String> _geminiOcr(File imageFile) async {
    // Enforce rate limiting before making the API call
    // This ensures we never exceed 6 requests per minute (10s interval)
    await _enforceRateLimit();
    
    final Uint8List imageBytes = await imageFile.readAsBytes();
    
    final content = [
      Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(
            'You are a high-fidelity Persian/Arabic OCR scanner. '
            'Extract ALL text from this image exactly as written. '
            'Preserve paragraph breaks and line structure. '
            'Output ONLY the extracted text, nothing else.',
          ),
      ]),
    ];

    final response = await _geminiModel.generateContent(content);
    final String? text = response.text;
    
    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini returned empty text');
    }
    
    return text.trim();
  }

  /// Cleanup resources
  Future<void> dispose() async {
    // No additional cleanup needed for cloud-only architecture
  }
}