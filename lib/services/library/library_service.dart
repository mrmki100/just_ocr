// lib/services/library/library_service.dart
// Abstract library service interface for managing scanned books
// 
// Features:
// - Save scanned documents to Isar database
// - Retrieve book list
// - Update reading position
// - Delete books
// - Search within books

import '../../data/models/scan_event.dart';

abstract class LibraryService {
  /// Initialize the library service
  Future<void> initialize();
  
  /// Save a newly scanned book to the database
  Future<Book> saveBook({
    required String title,
    required List<String> pages,
    required SourceType sourceType,
    String? filePath,
  });
  
  /// Get all books in the library
  Future<List<Book>> getAllBooks();
  
  /// Get a specific book by ID
  Future<Book?> getBookById(int id);
  
  /// Get a specific book by UUID
  Future<Book?> getBookByUuid(String uuid);
  
  /// Update a book's reading position
  Future<void> updateReadingPosition({
    required int bookId,
    required int pageIndex,
    required int paragraphIndex,
  });
  
  /// Mark a book as read (update lastReadAt)
  Future<void> markAsRead(int bookId);
  
  /// Delete a book from the library
  Future<void> deleteBook(int bookId);
  
  /// Search for text within all books
  Future<List<SearchResult>> searchInBooks(String query);
  
  /// Get books by status
  Future<List<Book>> getBooksByStatus(BookStatus status);
  
  /// Update book status
  Future<void> updateBookStatus(int bookId, BookStatus status);
  
  /// Set error message for a book
  Future<void> setBookError(int bookId, String errorMessage);
  
  /// Dispose resources
  void dispose();
}

/// Search result containing matching book and context
class SearchResult {
  final Book book;
  final String matchedText;
  final int pageIndex;
  final int matchStartIndex;
  
  SearchResult({
    required this.book,
    required this.matchedText,
    required this.pageIndex,
    required this.matchStartIndex,
  });
}
