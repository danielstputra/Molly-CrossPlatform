class ChatSession {
  final String id;
  String title;
  final DateTime updatedAt;
  final String? agentSlug;
  final String? lastMessage;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.agentSlug,
    this.lastMessage,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Percakapan Baru',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      agentSlug: json['agent_slug']?.toString(),
      lastMessage: json['last_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updated_at': updatedAt.toIso8601String(),
      'agent_slug': agentSlug,
      'last_message': lastMessage,
    };
  }
}
