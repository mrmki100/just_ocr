import 'dart:io';
// Notice how the line below uses the new file_selector package!
import 'package:file_selector/file_selector.dart';
import '../../data/models/scan_event.dart';
import '../logging/event_logger.dart';

class FilePickerService {
  final EventLogger _logger = EventLogger();

  Future<File?> pickSupportedDocument() async {
    try {
      // Define the allowed file types
      const XTypeGroup customGroup = XTypeGroup(
        label: 'documents',
        extensions: ['pdf', 'epub', 'jpg', 'jpeg', 'png'],
      );
      
      // Open the OS file picker
      final XFile? file = await openFile(acceptedTypeGroups: [customGroup]);

      if (file != null) {
        final selectedFile = File(file.path);
        
        await _logger.logEvent(
          severity: LogSeverity.info,
          module: 'Import',
          eventName: 'FileSelected',
          message: 'User selected a file: ${file.name}',
          technicalDetails: 'Path: ${file.path}',
        );
        
        return selectedFile;
      } else {
        // User backed out of the picker without selecting anything
        await _logger.logEvent(
          severity: LogSeverity.debug,
          module: 'Import',
          eventName: 'PickerCanceled',
          message: 'User closed the file picker without selecting a file.',
        );
        return null;
      }
    } catch (e, stack) {
      await _logger.logEvent(
        severity: LogSeverity.error,
        module: 'Import',
        eventName: 'PickerError',
        message: 'Failed to open the file picker.',
        technicalDetails: e.toString(),
      );
      return null;
    }
  }
}