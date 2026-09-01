import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/db_constants.dart';
import '../database/database_helper.dart';

class RestoreService {
  Future<bool> validateBackupFile(String path) async {
    final f = File(path);
    return f.existsSync() && f.lengthSync() > 0;
  }

  Future<void> restoreBackup(String path) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, DbConstants.databaseName);
    await DatabaseHelper.instance.close();
    await File(path).copy(dest);
  }
}
