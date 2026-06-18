// lib/services/ocr_service_impl.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:just_ocr/features/reader/book_notifier.dart';

class OcrServiceImpl implements OcrService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
    systemInstruction: Content.system(
      'You are a high-fidelity Arabic/Persian OCR scanner. '
      'Extract all Persian and English text verbatim. Maintain layout structure and line breaks. '
      'Do not translate, do not summarize, do not correct spelling mistakes. Output pure extracted text only.'
    ),
  );

  @override
  Future<List<String>> extractPages(
    File file, {
    required ProgressCallback onProgress,
  }) async {
    final String path = file.path.toLowerCase();
    final List<String> extractedTextCollection = [];

    if (path.endsWith('.pdf')) {
      onProgress('در حال باز کردن فایل PDF...', null);
      final PdfDocument document = await PdfDocument.openFile(file.path);
      final int totalPages = document.pagesCount;
      
      // Safety optimization limit for processing
      final int pagesToProcess = totalPages > 3 ? 3 : totalPages;

      for (int i = 1; i <= pagesToProcess; i++) {
        final double progressFraction = i / pagesToProcess;
        onProgress('در حال آماده‌سازی صفحه $i از $pagesToProcess...', progressFraction * 0.3);

        final PdfPage page = await document.getPage(i);
        final PdfPageImage? pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );
        await page.close();

        if (pageImage == null) continue;

        final Directory tempDir = await getTemporaryDirectory();
        final File tempImageFile = File('${tempDir.path}/page_slice_$i.jpg');
        await tempImageFile.writeAsBytes(pageImage.bytes);

        onProgress('در حال استخراج متن صفحه $i از $pagesToProcess...', 0.3 + (progressFraction * 0.7));
        final String pageText = await _executeVisionInference(tempImageFile);
        extractedTextCollection.add(pageText);

        await tempImageFile.delete();
      }
      await document.close();
    } else {
      onProgress('در حال استخراج متن تصویر...', 0.5);
      final String imageText = await _executeVisionInference(file);
      extractedTextCollection.add(imageText);
    }

    return extractedTextCollection;
  }

  Future<String> _executeVisionInference(File imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    
    final content = [
      Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart('Extract all text from this page accurately.'),
      ])
    ];

    final GenerateContentResponse response = await _model.generateContent(content);
    return response.text ?? '';
  }
}