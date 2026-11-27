class WorktreeModel {
  final String name;
  final String branch;
  final String path;
  final String commit;
  final bool isDefault;

  WorktreeModel({
    required this.name,
    required this.branch,
    required this.path,
    required this.commit,
    this.isDefault = false,
  });

  factory WorktreeModel.fromJson(Map<String, dynamic> json) {
    return WorktreeModel(
      name: json['name']?.toString() ?? 'worktree',
      branch: json['branch']?.toString() ?? json['name']?.toString() ?? 'branch',
      path: json['path']?.toString() ?? '',
      commit: json['head']?.toString() ?? json['commit']?.toString() ?? '',
      isDefault: json['is_default'] == true,
    );
  }
}
