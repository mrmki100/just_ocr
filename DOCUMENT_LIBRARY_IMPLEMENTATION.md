# Document Library Implementation - Save/Load Feature

## Overview
Complete implementation of a document library system for saving and loading OCR-processed documents with full error handling, state management, and persistence.

## Architecture

### 1. Data Models (`lib/data/models/`)

#### `scan_event.dart` (Enhanced)
Added comprehensive Book model with:
- **SourceType** enum: pdf, image, epub, camera
- **BookStatus** enum: processing, ready, error, deleted
- **Book** entity with:
  - Unique UUID for external references
  - Indexed title and status for fast queries
  - Pages list (extracted text)
  - Reading position tracking (page & paragraph)
  - Timestamps (createdAt, lastReadAt)
  - Reading statistics (totalReadingTimeSeconds)
  - Favorites support
  - Tags for organization
  - Computed properties (totalPages, readingProgress, isFullyRead)

#### `book.dart`
Re-export file for clean imports throughout the codebase.

#### `book.g.dart`
Isar schema generator output (manually created for immediate use without build_runner).

### 2. Database Layer (`lib/data/database/isar_service.dart`)

Enhanced IsarService with Book operations:
```dart
- saveBook(Book book)
- getAllBooks()
- getBookById(int id)
- getBookByUuid(String uuid)
- deleteBook(int id)
```

**Key Features:**
- Single Isar instance management
- Transaction-safe writes
- Type-safe queries
- Error propagation

### 3. Service Layer (`lib/services/library/`)

#### `library_service.dart` (Interface)
Abstract contract defining all library operations:
- CRUD operations for books
- Reading position management
- Status updates
- Full-text search
- Error tracking

#### `library_service_impl.dart` (Implementation)
Complete implementation with:

**Error Handling:**
- All methods wrapped in try-catch blocks
- Specific `FileOperationException` types thrown
- Validation checks (empty pages, invalid indices, not found)
- Proper error classification using existing `AppError` hierarchy

**Features Implemented:**
1. **saveBook()**: Validates pages, generates UUID, sets timestamps
2. **getAllBooks()**: Filters out deleted books, sorts by date
3. **getBookById()/getBookByUuid()**: Safe retrieval with null handling
4. **updateReadingPosition()**: Validates page bounds, updates timestamps
5. **markAsRead()**: Updates lastReadAt timestamp
6. **deleteBook()**: Soft delete (sets status to deleted)
7. **searchInBooks()**: Case-insensitive full-text search with context
8. **getBooksByStatus()**: Filter by status enum
9. **updateBookStatus()**: State transitions
10. **setBookError()**: Error tracking with messages

### 4. State Management (`lib/providers/library_provider.dart`)

Riverpod-based state management:

#### States (Sealed Class)
```dart
sealed class LibraryState
├── LibraryLoading      // Initial load
├── LibraryLoaded       // Books retrieved successfully
│   ├── favorites getter
│   ├── recentlyRead getter
│   ├── getByStatus()
│   └── searchByTitle()
└── LibraryError        // Error with AppError details
```

#### LibraryNotifier
StateNotifier with async operations:
- `initialize()`: Setup service and load books
- `loadBooks()`: Refresh from database
- `saveBook()`: Add new book with state update
- `deleteBook()`: Remove with state update
- `updateReadingPosition()`: Persist reading progress
- `toggleFavorite()`: Mark/unmark favorites
- `searchInBooks()`: Full-text search
- `retry()`: Recover from errors

**Error Boundaries:**
- All async methods catch exceptions
- Convert to AppError types
- Update state to LibraryError on failure
- Allow retry recovery

### 5. Integration Points

#### With Existing OCR Flow
The library integrates seamlessly with the current OCR pipeline:

```dart
// In BookNotifier or similar
final libraryService = ref.read(libraryServiceProvider);

// After successful OCR extraction:
await libraryService.saveBook(
  title: fileName,
  pages: extractedPages,
  sourceType: SourceType.pdf,
  filePath: file.path,
);
```

#### With Reader
Reading position automatically synced:
```dart
// When user navigates
await libraryService.updateReadingPosition(
  bookId: book.id,
  pageIndex: currentPage,
  paragraphIndex: currentParagraph,
);
```

## Error Handling Strategy

### Exception Types Used
All library operations use the existing `AppError` hierarchy:

1. **FileOperationException**
   - `corruptedFile`: Empty pages, invalid data
   - `fileNotFound`: Book doesn't exist
   - `permissionDenied`: Access issues
   - `unknown`: Generic failures

2. **Error Propagation**
   ```dart
   try {
     // Operation
   } on FileOperationException {
     rethrow; // Preserve typed errors
   } catch (e) {
     throw FileOperationException.fromException(e, 'operation_name');
   }
   ```

3. **Validation**
   - Empty page lists rejected before save
   - Page indices validated against book.pages.length
   - Null checks on book existence
   - Search query validation

## Usage Examples

### Initialize Library
```dart
// In main.dart or bootstrap
final libraryService = LibraryServiceImpl();
await libraryService.initialize();

// Or with Riverpod
ref.read(libraryNotifierProvider.notifier).initialize();
```

### Save Document
```dart
try {
  final book = await libraryService.saveBook(
    title: 'My Document',
    pages: ['Page 1 text', 'Page 2 text'],
    sourceType: SourceType.pdf,
    filePath: '/path/to/file.pdf',
  );
  print('Saved: ${book.uuid}');
} on FileOperationException catch (e) {
  print('Error: ${e.message}');
  print('Suggestion: ${e.recoverySuggestion}');
}
```

### Load All Books
```dart
final books = await libraryService.getAllBooks();
for (final book in books) {
  print('${book.title}: ${book.readingProgress * 100}% read');
}
```

### Update Reading Position
```dart
await libraryService.updateReadingPosition(
  bookId: 123,
  pageIndex: 5,
  paragraphIndex: 2,
);
```

### Search Across Library
```dart
final results = await libraryService.searchInBooks('query');
for (final result in results) {
  print('Found in: ${result.book.title}');
  print('Context: ...${result.matchedText}...');
  print('Page: ${result.pageIndex}');
}
```

### Riverpod Integration
```dart
class LibraryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryNotifierProvider);
    
    return switch (state) {
      LibraryLoading() => CircularProgressIndicator(),
      LibraryLoaded(books: final books) => ListView.builder(
        itemCount: books.length,
        itemBuilder: (_, i) => BookTile(book: books[i]),
      ),
      LibraryError(error: final error) => ErrorView(
        message: error.message,
        onRetry: () => ref.read(libraryNotifierProvider.notifier).retry(),
      ),
    };
  }
}
```

## Testing Considerations

### Unit Tests
```dart
test('saveBook validates empty pages', () async {
  expect(
    () => service.saveBook(title: 'Test', pages: [], ...),
    throwsA(isA<FileOperationException>()),
  );
});

test('updateReadingPosition validates page index', () async {
  final book = await service.saveBook(...);
  expect(
    () => service.updateReadingPosition(
      bookId: book.id,
      pageIndex: 999, // Out of bounds
      paragraphIndex: 0,
    ),
    throwsA(isA<FileOperationException>()),
  );
});
```

### Integration Tests
- Test full save/load cycle
- Verify soft delete behavior
- Test search functionality
- Validate reading position persistence

## Performance Optimizations

1. **Indexing**: Title and status fields indexed for fast queries
2. **Soft Delete**: Books marked deleted instead of removed (faster, recoverable)
3. **Lazy Loading**: Only load metadata in lists, full book on demand
4. **Debounced Writes**: Reading position updates can be debounced
5. **Cached Counts**: totalPages computed from pages.length (no extra storage)

## Accessibility Considerations

The implementation maintains the app's accessibility standards:
- Error messages are descriptive and actionable
- State changes can trigger live region announcements
- Reading position persists across sessions
- Search provides context snippets for screen readers

## Security Notes

1. **UUID**: Each book has unique identifier preventing ID enumeration
2. **Soft Delete**: Accidental deletions recoverable until hard cleanup
3. **Validation**: All inputs validated before database operations
4. **Error Messages**: User-friendly messages don't expose technical details

## Future Enhancements

Potential additions:
1. **Cloud Sync**: Backup library to cloud storage
2. **Export**: Export books as PDF/EPUB/text
3. **Annotations**: User notes and highlights
4. **Collections**: Group books into folders/categories
5. **Statistics**: Reading time analytics, words per minute
6. **Batch Operations**: Multi-select delete, export, tag
7. **OCR Re-processing**: Re-run OCR with different settings
8. **Version History**: Track changes to document text

## Files Modified/Created

### Created:
- `lib/data/models/book.dart` - Re-export
- `lib/data/models/book.g.dart` - Isar schema
- `lib/providers/library_provider.dart` - State management
- `DOCUMENT_LIBRARY_IMPLEMENTATION.md` - This documentation

### Modified:
- `lib/data/models/scan_event.dart` - Added Book model
- `lib/data/database/isar_service.dart` - Added Book operations
- `lib/services/library/library_service_impl.dart` - Enhanced error handling

### No Changes Required:
- `lib/services/library/library_service.dart` - Interface already complete

## Dependencies

All required dependencies already present in `pubspec.yaml`:
- `isar: ^3.1.0` - Database
- `isar_flutter_libs: ^3.1.0` - Flutter integration
- `uuid: ^4.5.3` - Unique identifiers
- `flutter_riverpod: ^2.6.1` - State management
- `equatable: ^2.0.7` - Value equality (already used)

## Conclusion

The document library implementation provides a robust, type-safe, and accessible way to save and load OCR-processed documents. It follows the existing architecture patterns, integrates seamlessly with the current codebase, and includes comprehensive error handling aligned with the app's error boundary strategy.
