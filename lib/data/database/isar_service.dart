import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_event.dart';

class IsarService {
  // We keep a single static instance of the database open
  static late Isar db;

  // Called once when the app starts
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    db = await Isar.open(
      [ScanEventSchema], // Add future schemas (like LocalBook) here
      directory: dir.path,
      inspector: true, // Allows us to view the DB in the browser later
    );
  }

  // Save an event to the database
  Future<void> saveEvent(ScanEvent event) async {
    await db.writeTxn(() async {
      await db.scanEvents.put(event);
    });
  }
}