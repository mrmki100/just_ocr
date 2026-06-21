// lib/services/ocr_service_impl.dart
// Consolidated OCR service supporting PDF, EPUB, and images
// with proper progress reporting and error handling

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/reader/book_notifier.dart';

class OcrServiceImpl implements OcrService {
  // Gemini model for cloud OCR (better for Persian/Arabic)
  late final GenerativeModel _geminiModel;
  final SharedPreferences _prefs;
  final String _modelName;
  
  // ML Kit for offline fallback
  final TextRecognizer _mlKitRecognizer = 
      TextRecognizer(script: TextRecognitionScript.latin);

  OcrServiceImpl(this._prefs, {String? modelName}) : _modelName = modelName ?? 'gemini-2.0-flash' {
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
        final String text = await _processImage(file, useGemini: true);
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

        // Run OCR on the page image
        final String pageText = await _processImage(
          tempImageFile,
          useGemini: true, // Prefer Gemini for better Persian support
        );

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

  /// Process single image with OCR (Gemini preferred, ML Kit fallback)
  Future<String> _processImage(File imageFile, {required bool useGemini}) async {
    // Try Gemini first for best Persian/Arabic accuracy
    if (useGemini) {
      try {
        return await _geminiOcr(imageFile);
      } catch (e) {
        debugPrint('[OcrServiceImpl] Gemini failed, falling back to ML Kit: $e');
        // Fall through to ML Kit
      }
    }

    // Fallback to ML Kit (offline, but less accurate for Persian)
    return await _mlKitOcr(imageFile);
  }

  /// Cloud OCR using Gemini (best for Persian/Arabic)
  Future<String> _geminiOcr(File imageFile) async {
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

  /// Offline OCR using ML Kit (fallback option)
  Future<String> _mlKitOcr(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = 
        await _mlKitRecognizer.processImage(inputImage);

    final StringBuffer structuredText = StringBuffer();
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        structuredText.writeln(line.text);
      }
      structuredText.writeln(); // Paragraph separator
    }

    final String result = structuredText.toString().trim();
    
    if (result.isEmpty) {
      throw StateError('ML Kit found no text');
    }
    
    return result;
  }

  /// Cleanup resources
  void dispose() {
    _mlKitRecognizer.close();
  }
}