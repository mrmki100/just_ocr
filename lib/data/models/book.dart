// lib/data/models/book.dart
// 
// Re-exports Book model from scan_event.dart to maintain clean imports.
// The actual Book class definition is in scan_event.dart to keep all
// Isar collections in a single file for code generation simplicity.

export 'scan_event.dart' show Book, SourceType, BookStatus;
