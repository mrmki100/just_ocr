import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../data/models/scan_event.dart'; 
import '../logging/event_logger.dart';
import '../ocr/gemini_ocr_service.dart';

class PdfParserService {
  final EventLogger _logger = EventLogger();
  final GeminiOcrService _ocrService = GeminiOcrService();

  // Added the 'onProgress' function here
  Future<List<String>?> extractTextFromPdf( // 👈 CHANGE 'String?' TO 'List<String>?'
    File pdfFile, {
    Function(int current, int total, String status)? onProgress,
  }) async {
    try {
      await _logger.logEvent(
        severity: LogSeverity.info,
        module: 'PDF Parser',
        eventName: 'ParseStarted',
        message: 'Opening PDF: ${pdfFile.path.split(Platform.pathSeparator).last}',
      );

      final document = await PdfDocument.openFile(pdfFile.path);
      final tempDir = await getTemporaryDirectory();
      List<String> extractedPages = []; // 👈 CHANGE THIS LINE

      final pageCount = document.pagesCount;
      final limit = pageCount > 3 ? 3 : pageCount;

      // Tell UI we are starting
      onProgress?.call(0, limit, 'Opening PDF Document...');

      for (int i = 1; i <= limit; i++) {
        // Tell UI which page is slicing
        onProgress?.call(i, limit, 'Slicing Page $i of $limit...');
        
        final page = await document.getPage(i);
        
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );

        if (pageImage != null) {
          final tempFile = File('${tempDir.path}/temp_page_$i.jpg');
          await tempFile.writeAsBytes(pageImage.bytes);

          // Tell UI we are sending to Gemini
          onProgress?.call(i, limit, 'Uploading Page $i to Gemini...');
          
          final pageText = await _ocrService.processImage(tempFile);
          
          extractedPages.add(pageText ?? '❌ No text detected on this page.');

          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
        await page.close(); 
      }
      
      await document.close();
      _ocrService.dispose();

      return extractedPages; // 👈 CHANGE THIS LINE

    } catch (e) {
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'PDF Parser',
        eventName: 'ParseFailed',
        message: 'Failed to extract text from PDF.',
        technicalDetails: e.toString(),
      );
      // Return the crash error so the UI can show it!
      return ["❌ PDF PARSER CRASHED:\n${e.toString()}"]; // 👈 CHANGE THIS LINE
    }
  }
}