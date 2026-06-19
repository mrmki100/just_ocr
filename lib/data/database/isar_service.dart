import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_event.dart';

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
}