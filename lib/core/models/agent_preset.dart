class AgentPreset {
  final String id;
  final String name;
  final String category;
  final String description;
  final String model;
  final List<String> skills;
  final String systemPrompt;
  final bool isCustom;

  const AgentPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.model = 'gpt-4o',
    this.skills = const [],
    this.systemPrompt = '',
    this.isCustom = false,
  });

  factory AgentPreset.fromJson(Map<String, dynamic> json) {
    return AgentPreset(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? json['title'] ?? 'Agen Molly',
      category: json['category'] ?? 'Umum',
      description: json['description'] ?? 'Asisten AI cerdas untuk otomasi alur kerja.',
      model: json['model'] ?? 'gpt-4o',
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      systemPrompt: json['system_prompt'] ?? json['prompt'] ?? '',
      isCustom: json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'model': model,
      'skills': skills,
      'system_prompt': systemPrompt,
      'is_custom': isCustom,
    };
  }
}
