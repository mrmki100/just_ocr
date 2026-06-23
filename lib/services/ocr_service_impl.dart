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
import '../core/error/app_error.dart';
import '../features/reader/book_notifier.dart';

class OcrServiceImpl implements OcrService {
  // Gemini model for cloud OCR (better for Persian/Arabic)
  late final GenerativeModel _geminiModel;
  final SharedPreferences _prefs;
  
  // ML Kit for offline fallback
  final TextRecognizer _mlKitRecognizer = 
      TextRecognizer(script: TextRecognitionScript.latin);

  OcrServiceImpl(this._prefs) {
    // API key will be retrieved from SharedPreferences at runtime
    final apiKey = _prefs.getString('gemini_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      debugPrint('⚠️ WARNING: GEMINI_API_KEY not provided. Cloud OCR will fail.');
    }
    
    _geminiModel = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
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
        
        // Rate limiting: wait 20 seconds before processing the next page
        // to comply with Gemini's RPM (Requests Per Minute) limits
        if (i < pagesToProcess) {
          await Future.delayed(const Duration(seconds: 20));
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
  /// 
  /// Throws [OcrException] if both Gemini and ML Kit fail.
  Future<String> _processImage(File imageFile, {required bool useGemini}) async {
    // Try Gemini first for best Persian/Arabic accuracy
    if (useGemini) {
      try {
        return await _geminiOcr(imageFile);
      } on GeminiApiException catch (e) {
        debugPrint('[OcrServiceImpl] Gemini API error: ${e.message}');
        // Only fallback to ML Kit if the error allows it
        if (!e.canFallback) {
          throw OcrException(
            message: 'Cloud OCR authentication failed. Please check your API key.',
            technicalDetails: e.technicalDetails,
            failureType: OcrFailureType.authenticationFailed,
          );
        }
        // Fallback to ML Kit
        debugPrint('[OcrServiceImpl] Falling back to ML Kit...');
      } on OcrException catch (e) {
        debugPrint('[OcrServiceImpl] Gemini OCR error: ${e.message}');
        // Retryable errors can fallback
        if (e.isRetryable || e.canFallback) {
          debugPrint('[OcrServiceImpl] Falling back to ML Kit...');
        } else {
          rethrow;
        }
      } catch (e) {
        debugPrint('[OcrServiceImpl] Unexpected Gemini error, falling back to ML Kit: $e');
        // Fall through to ML Kit
      }
    }

    // Fallback to ML Kit (offline, but less accurate for Persian)
    try {
      return await _mlKitOcr(imageFile);
    } on AppError {
      rethrow;
    } catch (e) {
      throw OcrException(
        message: 'Both cloud and local OCR failed.',
        technicalDetails: e.toString(),
        failureType: OcrFailureType.unknown,
      );
    }
  }

  /// Cloud OCR using Gemini (best for Persian/Arabic)
  /// 
  /// Throws [GeminiApiException] for API errors.
  /// Throws [OcrException] when no text is detected.
  /// Throws [FileOperationException] for file I/O errors.
  Future<String> _geminiOcr(File imageFile) async {
    final Uint8List imageBytes;
    try {
      imageBytes = await imageFile.readAsBytes();
    } catch (e) {
      throw FileOperationException(
        message: 'Failed to read image file for OCR.',
        technicalDetails: e.toString(),
        operationType: FileOperationType.readFailed,
      );
    }
    
    if (imageBytes.isEmpty) {
      throw OcrException(
        message: 'Image file is empty.',
        failureType: OcrFailureType.invalidImageFormat,
      );
    }
    
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

    String? text;
    try {
      final response = await _geminiModel.generateContent(content);
      text = response.text;
    } on ClientException catch (e) {
      final apiError = GeminiApiException.fromException(e);
      throw apiError;
    } on ApiException catch (e) {
      final apiError = GeminiApiException.fromException(e);
      throw apiError;
    } catch (e) {
      throw GeminiApiException.fromException(e);
    }
    
    if (text == null || text.trim().isEmpty) {
      throw OcrException(
        message: 'Gemini returned no text.',
        failureType: OcrFailureType.noTextDetected,
      );
    }
    
    return text.trim();
  }

  /// Offline OCR using ML Kit (fallback option)
  /// 
  /// Throws [MLKitException] for ML Kit processing errors.
  /// Throws [OcrException] when no text is detected.
  /// Throws [FileOperationException] for file I/O errors.
  Future<String> _mlKitOcr(File imageFile) async {
    InputImage inputImage;
    try {
      inputImage = InputImage.fromFile(imageFile);
    } catch (e) {
      throw FileOperationException(
        message: 'Failed to load image for ML Kit.',
        technicalDetails: e.toString(),
        operationType: FileOperationType.readFailed,
      );
    }

    final RecognizedText recognizedText;
    try {
      recognizedText = await _mlKitRecognizer.processImage(inputImage);
    } catch (e) {
      throw MLKitException.fromException(e);
    }

    final StringBuffer structuredText = StringBuffer();
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        structuredText.writeln(line.text);
      }
      structuredText.writeln(); // Paragraph separator
    }

    final String result = structuredText.toString().trim();
    
    if (result.isEmpty) {
      throw OcrException(
        message: 'ML Kit found no text in the image.',
        failureType: OcrFailureType.noTextDetected,
      );
    }
    
    return result;
  }

  /// Cleanup resources
  void dispose() {
    _mlKitRecognizer.close();
  }
}