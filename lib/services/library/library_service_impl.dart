// lib/services/library/library_service_impl.dart
// Isar implementation of library service for managing scanned books
// 
// Features:
// - Save scanned documents to Isar database
// - Retrieve book list sorted by date
// - Update reading position with persistence
// - Delete books
// - Full-text search within books

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
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
        throw StateError('Isar database not initialized. Call IsarService.initialize() first.');
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
    } catch (e) {
      debugPrint('[LibraryService] Save book failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Book>> getAllBooks() async {
    try {
      final books = await _isar.books
          .filter()
          .statusNotEqualTo(BookStatus.deleted)
          .sortByCreatedAtDesc()
          .findAll();
      
      debugPrint('[LibraryService] Retrieved ${books.length} books');
      return books;
    } catch (e) {
      debugPrint('[LibraryService] Get all books failed: $e');
      return [];
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
      return null;
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
      return null;
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
          book.lastPageIndex = pageIndex;
          book.lastParagraphIndex = paragraphIndex;
          book.lastReadAt = DateTime.now();
          await _isar.books.put(book);
        }
      });
      debugPrint('[LibraryService] Updated reading position for book $bookId: page $pageIndex, paragraph $paragraphIndex');
    } catch (e) {
      debugPrint('[LibraryService] Update reading position failed: $e');
      rethrow;
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
        }
      });
      debugPrint('[LibraryService] Marked book $bookId as read');
    } catch (e) {
      debugPrint('[LibraryService] Mark as read failed: $e');
      rethrow;
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
        }
      });
      debugPrint('[LibraryService] Deleted book $bookId');
    } catch (e) {
      debugPrint('[LibraryService] Delete book failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<SearchResult>> searchInBooks(String query) async {
    try {
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
    } catch (e) {
      debugPrint('[LibraryService] Search failed: $e');
      return [];
    }
  }
  
  @override
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    try {
      final books = await _isar.books
          .filter()
          .statusEqualTo(status)
          .sortByCreatedAtDesc()
          .findAll();
      
      debugPrint('[LibraryService] Retrieved ${books.length} books with status $status');
      return books;
    } catch (e) {
      debugPrint('[LibraryService] Get books by status failed: $e');
      return [];
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
        }
      });
      debugPrint('[LibraryService] Updated book $bookId status to $status');
    } catch (e) {
      debugPrint('[LibraryService] Update book status failed: $e');
      rethrow;
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
        }
      });
      debugPrint('[LibraryService] Set error for book $bookId: $errorMessage');
    } catch (e) {
      debugPrint('[LibraryService] Set book error failed: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    debugPrint('[LibraryService] Disposed');
  }
}
