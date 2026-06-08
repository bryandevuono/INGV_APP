import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openAppDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final databasePath = path.join(directory.path, 'ingv_app.db');
  return databaseFactoryIo.openDatabase(databasePath);
}
