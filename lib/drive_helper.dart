import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class DriveHelper {
  static const String _dbName = "ExpenseTracker.db"; 

  // ব্যাকআপ নেওয়ার ফাংশন
  static Future<bool> uploadBackup(GoogleSignInAccount account) async {
    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final dbPath = join(await getDatabasesPath(), _dbName);
      final file = File(dbPath);
      if (!await file.exists()) return false; 

      final fileList = await driveApi.files.list(q: "name = '$_dbName' and trashed = false");
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var f in fileList.files!) {
          await driveApi.files.delete(f.id!);
        }
      }

      final driveFile = drive.File()..name = _dbName;
      final media = drive.Media(file.openRead(), file.lengthSync());
      await driveApi.files.create(driveFile, uploadMedia: media);
      return true;
    } catch (e) {
      print("Backup Error: $e");
      return false;
    }
  }

  // রিস্টোর করার ফাংশন
  static Future<bool> restoreBackup(GoogleSignInAccount account) async {
    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final fileList = await driveApi.files.list(q: "name = '$_dbName' and trashed = false");
      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final String fileId = fileList.files!.first.id!;
      final drive.Media response = await driveApi.files.get(
        fileId, 
        downloadOptions: drive.DownloadOptions.fullMedia
      ) as drive.Media;

      final dbPath = join(await getDatabasesPath(), _dbName);
      final file = File(dbPath);

      List<int> dataStore = [];
      await for (var data in response.stream) {
        dataStore.addAll(data);
      }
      await file.writeAsBytes(dataStore);
      return true;
    } catch (e) {
      print("Restore Error: $e");
      return false;
    }
  }
}