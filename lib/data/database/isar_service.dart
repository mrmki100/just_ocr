import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_event.dart';
import '../models/book.dart';

class IsarService {
  // We keep a single static instance of the database open
  static late Isar db;
  
  // Flag to track initialization
  static bool _initialized = false;

  // Called once when the app starts
  static Future<void> initialize() async {
    if (_initialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [
        ScanEventSchema,
        BookSchema,
      ],
      directory: dir.path,
      inspector: true, // Allows us to view the DB in the browser later
    );
    
    _initialized = true;
  }
  
  // Get the Isar instance (throws if not initialized)
  static Isar getInstance() {
    if (!_initialized) {
      throw StateError('Isar database not initialized. Call IsarService.initialize() first.');
    }
    return db;
  }

  // Save an event to the database
  Future<void> saveEvent(ScanEvent event) async {
    await db.writeTxn(() async {
      await db.scanEvents.put(event);
    });
  }
  
  // Save a book to the database
  Future<void> saveBook(Book book) async {
    await db.writeTxn(() async {
      await db.books.put(book);
    });
  }
  
  // Get all books from the database
  Future<List<Book>> getAllBooks() async {
    return await db.books.where().findAll();
  }
  
  // Get a book by ID
  Future<Book?> getBookById(int id) async {
    return await db.books.get(id);
  }
  
  // Get a book by UUID
  Future<Book?> getBookByUuid(String uuid) async {
    return await db.books.filter().uuidEqualTo(uuid).findFirst();
  }
  
  // Delete a book from the database
  Future<void> deleteBook(int id) async {
    await db.writeTxn(() async {
      await db.books.delete(id);
    });
  }
}