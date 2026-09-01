import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/db_constants.dart';

class BackupService {
  Future<String> createBackup(String folderPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final src = File(p.join(dir.path, DbConstants.databaseName));
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final dest = p.join(folderPath, 'hardware_store_backup_$stamp.db');
    await src.copy(dest);
    return dest;
  }
}
