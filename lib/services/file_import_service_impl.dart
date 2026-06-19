import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileImportServiceImpl {
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