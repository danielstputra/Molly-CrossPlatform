class ExtensionTool {
  final String id;
  final String name;
  final String category; // 'builtin', 'mcp', 'plugin', 'skill'
  final String description;
  final bool isEnabled;
  final Map<String, dynamic> parameters;

  const ExtensionTool({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.isEnabled = true,
    this.parameters = const {},
  });

  factory ExtensionTool.fromJson(Map<String, dynamic> json) {
    return ExtensionTool(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? json['display_name'] ?? 'Tool Agen',
      category: json['category'] ?? 'builtin',
      description: json['description'] ?? json['config_guide'] ?? '',
      isEnabled: json['is_enabled'] ?? json['enabled'] ?? true,
      parameters: json['parameters'] ?? {},
    );
  }
}
