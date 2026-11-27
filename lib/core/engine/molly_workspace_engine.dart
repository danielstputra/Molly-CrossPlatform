import 'dart:convert';
import '../database/molly_local_database.dart';

class LocalFileDiff {
  final String fileName;
  final int additions;
  final int deletions;
  final String formattedDiff;

  const LocalFileDiff({
    required this.fileName,
    required this.additions,
    required this.deletions,
    required this.formattedDiff,
  });
}

class MollyWorkspaceEngine {
  MollyWorkspaceEngine._();
  static final MollyWorkspaceEngine instance = MollyWorkspaceEngine._();

  final _db = MollyLocalDatabase.instance;

  Future<List<Map<String, dynamic>>> listFiles() async {
    return await _db.getWorkspaceFiles();
  }

  Future<void> createFile({
    required String fileName,
    required String content,
    String? fileType,
  }) async {
    final id = 'file-${DateTime.now().millisecondsSinceEpoch}';
    await _db.saveWorkspaceFile(
      id: id,
      fileName: fileName,
      filePath: '/molly/workspace/$fileName',
      content: content,
      fileType: fileType,
    );
  }

  /// Calculates a clean line-by-line Diff between two versions directly in Dart
  LocalFileDiff computeDiff({
    required String fileName,
    required String oldContent,
    required String newContent,
  }) {
    final oldLines = oldContent.split('\n');
    final newLines = newContent.split('\n');

    final diffBuf = StringBuffer();
    int adds = 0;
    int dels = 0;

    diffBuf.writeln('--- a/$fileName');
    diffBuf.writeln('+++ b/$fileName');
    diffBuf.writeln('@@ -1,${oldLines.length} +1,${newLines.length} @@');

    final maxLen = oldLines.length > newLines.length ? oldLines.length : newLines.length;

    for (int i = 0; i < maxLen; i++) {
      if (i < oldLines.length && i < newLines.length) {
        if (oldLines[i] == newLines[i]) {
          diffBuf.writeln(' ${oldLines[i]}');
        } else {
          diffBuf.writeln('-${oldLines[i]}');
          diffBuf.writeln('+${newLines[i]}');
          dels++;
          adds++;
        }
      } else if (i < oldLines.length) {
        diffBuf.writeln('-${oldLines[i]}');
        dels++;
      } else if (i < newLines.length) {
        diffBuf.writeln('+${newLines[i]}');
        adds++;
      }
    }

    return LocalFileDiff(
      fileName: fileName,
      additions: adds,
      deletions: dels,
      formattedDiff: diffBuf.toString(),
    );
  }
}
