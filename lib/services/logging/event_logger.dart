import 'package:logger/logger.dart';
import '../../data/models/scan_event.dart';
import '../../data/database/isar_service.dart';

class EventLogger {
  final Logger _consoleLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, 
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  final IsarService _isarService = IsarService();

  Future<void> logEvent({
    required LogSeverity severity,
    required String module,
    required String eventName,
    required String message,
    String? technicalDetails,
    String? documentId,
    int? pageIndex,
    String? engineName,
  }) async {
    // 1. Log to console for debugging during development
    _printToConsole(severity, '[$module] $eventName: $message');

    // 2. Create the database event object
    final event = ScanEvent()
      ..timestamp = DateTime.now()
      ..severity = severity
      ..module = module
      ..eventName = eventName
      ..message = message
      ..technicalDetails = technicalDetails
      ..documentId = documentId
      ..pageIndex = pageIndex
      ..engineName = engineName;

    // 3. Save to local database for the diagnostics screen
    await _isarService.saveEvent(event);
  }

  void _printToConsole(LogSeverity severity, String logMessage) {
    switch (severity) {
      case LogSeverity.debug:
        _consoleLogger.d(logMessage);
        break;
      case LogSeverity.info:
        _consoleLogger.i(logMessage);
        break;
      case LogSeverity.warning:
        _consoleLogger.w(logMessage);
        break;
      case LogSeverity.error:
      case LogSeverity.critical:
        _consoleLogger.e(logMessage);
        break;
    }
  }
}