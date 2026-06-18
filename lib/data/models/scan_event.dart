import 'package:isar/isar.dart';

part 'scan_event.g.dart'; // Required for Isar code generation

@collection
class ScanEvent {
  Id id = Isar.autoIncrement;

  late DateTime timestamp;

  @enumerated
  late LogSeverity severity;

  late String module;
  late String eventName;
  late String message;

  String? technicalDetails;
  String? documentId;
  int? pageIndex;
  String? engineName;
}

enum LogSeverity {
  debug,
  info,
  warning,
  error,
  critical
}