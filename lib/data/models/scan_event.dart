import 'package:isar/isar.dart';

part 'scan_event.g.dart'; // Required for Isar code generation
part 'book.g.dart'; // Required for Isar code generation - contains BookSchema and extensions

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

// ---------------------------------------------------------------------------
// Book Model - Document Library Entity
// ---------------------------------------------------------------------------

/// Source type for imported documents
enum SourceType {
  /// PDF file import
  pdf,
  
  /// Image file import (JPG, PNG, etc.)
  image,
  
  /// EPUB file import
  epub,
  
  /// Camera capture
  camera,
}

/// Status of a book in the library
enum BookStatus {
  /// Processing/pending
  processing,
  
  /// Ready to read
  ready,
  
  /// Error during processing
  error,
  
  /// Soft-deleted (hidden from user)
  deleted,
}

/// Book entity stored in Isar database
@collection
class Book {
  /// Auto-increment primary key
  Id id = Isar.autoIncrement;
  
  /// Unique identifier for external references
  @unique
  late String uuid;
  
  /// Book title (auto-generated from filename or user-provided)
  @Index()
  late String title;
  
  /// Path to the original file (if applicable)
  String? filePath;
  
  /// Type of source document
  @enumerated
  late SourceType sourceType;
  
  /// Current status of the book
  @enumerated
  @Index()
  late BookStatus status;
  
  /// Extracted text pages (one string per page)
  late List<String> pages;
  
  /// Optional error message if status is error
  String? errorMessage;
  
  /// Last read page index (0-based)
  int lastPageIndex = 0;
  
  /// Last read paragraph index within the page (0-based)
  int lastParagraphIndex = 0;
  
  /// Creation timestamp
  late DateTime createdAt;
  
  /// Last access timestamp
  late DateTime lastReadAt;
  
  /// Total reading time in seconds (accumulated across sessions)
  int totalReadingTimeSeconds = 0;
  
  /// Whether the book has been marked as favorite
  bool isFavorite = false;
  
  /// Tags for organization (comma-separated or JSON array)
  String? tags;
  
  /// Computed property: total number of pages
  int get totalPages => pages.length;
  
  /// Computed property: reading progress (0.0 to 1.0)
  double get readingProgress => totalPages > 0 
      ? (lastPageIndex + 1) / totalPages 
      : 0.0;
  
  /// Computed property: whether the book has been fully read
  bool get isFullyRead => lastPageIndex >= totalPages - 1;
  
  @override
  String toString() => 'Book(id: $id, uuid: $uuid, title: "$title", pages: $totalPages)';
}