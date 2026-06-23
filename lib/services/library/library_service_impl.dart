// lib/services/library/library_service_impl.dart
// Isar implementation of library service for managing scanned books
// 
// Features:
// - Save scanned documents to Isar database
// - Retrieve book list sorted by date
// - Update reading position with persistence
// - Delete books
// - Full-text search within books
// - Error handling with AppError hierarchy

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/app_error.dart';
import '../../data/models/scan_event.dart';
import 'library_service.dart';

class LibraryServiceImpl implements LibraryService {
  late final Isar _isar;
  final Uuid _uuid = const Uuid();
  
  @override
  Future<void> initialize() async {
    try {
      _isar = await Isar.getInstance();
      if (_isar == null) {
        throw const FileOperationException(
          message: 'Isar database not initialized. Call IsarService.initialize() first.',
          operationType: FileOperationType.unknown,
        );
      }
      
      // Ensure books collection exists
      if (!_isar.collections.containsKey('Book')) {
        debugPrint('[LibraryService] Warning: Book collection not found in Isar schema');
      }
      
      debugPrint('[LibraryService] Initialized successfully');
    } catch (e) {
      debugPrint('[LibraryService] Initialization failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<Book> saveBook({
    required String title,
    required List<String> pages,
    required SourceType sourceType,
    String? filePath,
  }) async {
    try {
      if (pages.isEmpty) {
        throw const FileOperationException(
          message: 'Cannot save book with no pages.',
          operationType: FileOperationType.corruptedFile,
        );
      }
      
      final book = Book()
        ..uuid = _uuid.v4()
        ..title = title
        ..filePath = filePath
        ..sourceType = sourceType
        ..status = BookStatus.ready
        ..pages = pages
        ..createdAt = DateTime.now()
        ..lastReadAt = DateTime.now()
        ..lastPageIndex = 0
        ..lastParagraphIndex = 0;
      
      await _isar.writeTxn(() async {
        await _isar.books.put(book);
      });
      
      debugPrint('[LibraryService] Saved book: ${book.title} (${book.pages.length} pages)');
      return book;
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Save book failed: $e');
      throw FileOperationException.fromException(e, 'save_book');
    }
  }
  
  @override
  Future<List<Book>> getAllBooks() async {
    try {
      final books = await _isar.books
          .filter()
          .statusNotEqualTo(BookStatus.deleted)
          .findAll();
      
      // Sort in memory since sortByCreatedAtDesc is not properly generated
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('[LibraryService] Retrieved ${books.length} books');
      return books;
    } catch (e) {
      debugPrint('[LibraryService] Get all books failed: $e');
      throw FileOperationException.fromException(e, 'get_all_books');
    }
  }
  
  @override
  Future<Book?> getBookById(int id) async {
    try {
      final book = await _isar.books.get(id);
      debugPrint('[LibraryService] Retrieved book by ID: $id');
      return book;
    } catch (e) {
      debugPrint('[LibraryService] Get book by ID failed: $e');
      throw FileOperationException.fromException(e, 'get_book_by_id');
    }
  }
  
  @override
  Future<Book?> getBookByUuid(String uuid) async {
    try {
      final book = await _isar.books.filter().uuidEqualTo(uuid).findFirst();
      debugPrint('[LibraryService] Retrieved book by UUID: $uuid');
      return book;
    } catch (e) {
      debugPrint('[LibraryService] Get book by UUID failed: $e');
      throw FileOperationException.fromException(e, 'get_book_by_uuid');
    }
  }
  
  @override
  Future<void> updateReadingPosition({
    required int bookId,
    required int pageIndex,
    required int paragraphIndex,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final book = await _isar.books.get(bookId);
        if (book != null) {
          if (pageIndex < 0 || pageIndex >= book.pages.length) {
            throw const FileOperationException(
              message: 'Invalid page index.',
              operationType: FileOperationType.corruptedFile,
            );
          }
          book.lastPageIndex = pageIndex;
          book.lastParagraphIndex = paragraphIndex;
          book.lastReadAt = DateTime.now();
          await _isar.books.put(book);
        } else {
          throw const FileOperationException(
            message: 'Book not found.',
            operationType: FileOperationType.fileNotFound,
          );
        }
      });
      debugPrint('[LibraryService] Updated reading position for book $bookId: page $pageIndex, paragraph $paragraphIndex');
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Update reading position failed: $e');
      throw FileOperationException.fromException(e, 'update_reading_position');
    }
  }
  
  @override
  Future<void> markAsRead(int bookId) async {
    try {
      await _isar.writeTxn(() async {
        final book = await _isar.books.get(bookId);
        if (book != null) {
          book.lastReadAt = DateTime.now();
          await _isar.books.put(book);
        } else {
          throw const FileOperationException(
            message: 'Book not found.',
            operationType: FileOperationType.fileNotFound,
          );
        }
      });
      debugPrint('[LibraryService] Marked book $bookId as read');
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Mark as read failed: $e');
      throw FileOperationException.fromException(e, 'mark_as_read');
    }
  }
  
  @override
  Future<void> deleteBook(int bookId) async {
    try {
      // Soft delete: mark as deleted instead of removing from database
      await _isar.writeTxn(() async {
        final book = await _isar.books.get(bookId);
        if (book != null) {
          book.status = BookStatus.deleted;
          await _isar.books.put(book);
        } else {
          throw const FileOperationException(
            message: 'Book not found.',
            operationType: FileOperationType.fileNotFound,
          );
        }
      });
      debugPrint('[LibraryService] Deleted book $bookId');
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Delete book failed: $e');
      throw FileOperationException.fromException(e, 'delete_book');
    }
  }
  
  @override
  Future<List<SearchResult>> searchInBooks(String query) async {
    try {
      if (query.trim().isEmpty) {
        throw const FileOperationException(
          message: 'Search query cannot be empty.',
          operationType: FileOperationType.corruptedFile,
        );
      }
      
      final results = <SearchResult>[];
      final lowercaseQuery = query.toLowerCase();
      
      final books = await getAllBooks();
      
      for (final book in books) {
        for (int pageIndex = 0; pageIndex < book.pages.length; pageIndex++) {
          final pageText = book.pages[pageIndex];
          final lowercasePageText = pageText.toLowerCase();
          
          int startIndex = 0;
          while (true) {
            final matchIndex = lowercasePageText.indexOf(lowercaseQuery, startIndex);
            if (matchIndex == -1) break;
            
            // Extract context around the match (50 chars before and after)
            final contextStart = (matchIndex - 50).clamp(0, pageText.length);
            final contextEnd = (matchIndex + query.length + 50).clamp(0, pageText.length);
            final matchedText = pageText.substring(contextStart, contextEnd);
            
            results.add(SearchResult(
              book: book,
              matchedText: matchedText,
              pageIndex: pageIndex,
              matchStartIndex: matchIndex,
            ));
            
            startIndex = matchIndex + 1;
          }
        }
      }
      
      debugPrint('[LibraryService] Search found ${results.length} matches for "$query"');
      return results;
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Search failed: $e');
      throw FileOperationException.fromException(e, 'search_in_books');
    }
  }
  
  @override
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    try {
      final books = await _isar.books
          .filter()
          .statusEqualTo(status)
          .findAll();
      
      // Sort in memory since sortByCreatedAtDesc is not properly generated
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('[LibraryService] Retrieved ${books.length} books with status $status');
      return books;
    } catch (e) {
      debugPrint('[LibraryService] Get books by status failed: $e');
      throw FileOperationException.fromException(e, 'get_books_by_status');
    }
  }
  
  @override
  Future<void> updateBookStatus(int bookId, BookStatus status) async {
    try {
      await _isar.writeTxn(() async {
        final book = await _isar.books.get(bookId);
        if (book != null) {
          book.status = status;
          await _isar.books.put(book);
        } else {
          throw const FileOperationException(
            message: 'Book not found.',
            operationType: FileOperationType.fileNotFound,
          );
        }
      });
      debugPrint('[LibraryService] Updated book $bookId status to $status');
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Update book status failed: $e');
      throw FileOperationException.fromException(e, 'update_book_status');
    }
  }
  
  @override
  Future<void> setBookError(int bookId, String errorMessage) async {
    try {
      await _isar.writeTxn(() async {
        final book = await _isar.books.get(bookId);
        if (book != null) {
          book.status = BookStatus.error;
          book.errorMessage = errorMessage;
          await _isar.books.put(book);
        } else {
          throw const FileOperationException(
            message: 'Book not found.',
            operationType: FileOperationType.fileNotFound,
          );
        }
      });
      debugPrint('[LibraryService] Set error for book $bookId: $errorMessage');
    } on FileOperationException {
      rethrow;
    } catch (e) {
      debugPrint('[LibraryService] Set book error failed: $e');
      throw FileOperationException.fromException(e, 'set_book_error');
    }
  }
  
  @override
  void dispose() {
    debugPrint('[LibraryService] Disposed');
  }
}
