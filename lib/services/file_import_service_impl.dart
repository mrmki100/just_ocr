// lib/services/file_import_service_impl.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:just_ocr/features/reader/book_notifier.dart';

class FileImportServiceImpl implements FileImportService {
  @override
  Future<File?> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }
    return File(result.files.single.path!);
  }
}