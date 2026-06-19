import 'dart:io';
import 'package:file_selector/file_selector.dart';
import '../features/reader/book_notifier.dart';

class FileImportServiceImpl implements FileImportService {
  @override
  Future<File?> pickFile() async {
    // Define accepted file types
    final List<XTypeGroup> typeGroups = [
      const XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'png', 'jpg', 'jpeg'],
      ),
    ];

    // Open file selector
    final XFile? xFile = await openFile(acceptedTypeGroups: typeGroups);

    if (xFile == null) {
      return null;
    }

    // Convert XFile to File
    return File(xFile.path);
  }

  @override
  List<String> getSupportedFormats() {
    return ['pdf', 'png', 'jpg', 'jpeg'];
  }
}