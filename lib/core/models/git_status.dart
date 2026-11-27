class ModifiedFileModel {
  final String file;
  final String status;
  final int insertions;
  final int deletions;

  ModifiedFileModel({
    required this.file,
    required this.status,
    this.insertions = 0,
    this.deletions = 0,
  });

  factory ModifiedFileModel.fromJson(Map<String, dynamic> json) {
    return ModifiedFileModel(
      file: json['file']?.toString() ?? '',
      status: json['status']?.toString() ?? 'M',
      insertions: json['insertions'] is int ? json['insertions'] : int.tryParse(json['insertions']?.toString() ?? '0') ?? 0,
      deletions: json['deletions'] is int ? json['deletions'] : int.tryParse(json['deletions']?.toString() ?? '0') ?? 0,
    );
  }
}

class GitStatusModel {
  final String branch;
  final String lastCommit;
  final int modifiedCount;
  final List<ModifiedFileModel> files;

  GitStatusModel({
    required this.branch,
    required this.lastCommit,
    required this.modifiedCount,
    required this.files,
  });

  factory GitStatusModel.fromJson(Map<String, dynamic> json) {
    var rawFiles = json['files'] ?? [];
    List<ModifiedFileModel> filesList = [];
    if (rawFiles is List) {
      filesList = rawFiles
          .whereType<Map<String, dynamic>>()
          .map((f) => ModifiedFileModel.fromJson(f))
          .toList();
    }

    return GitStatusModel(
      branch: json['branch']?.toString() ?? 'main',
      lastCommit: json['last_commit']?.toString() ?? '',
      modifiedCount: json['modified_files_count'] is int
          ? json['modified_files_count']
          : filesList.length,
      files: filesList,
    );
  }
}
