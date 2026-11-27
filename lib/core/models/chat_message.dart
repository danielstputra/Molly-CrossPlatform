class ToolInvocation {
  final String id;
  final String toolName;
  final Map<String, dynamic> args;
  final dynamic result;
  final String status; // 'running', 'completed', 'error'

  ToolInvocation({
    required this.id,
    required this.toolName,
    required this.args,
    this.result,
    this.status = 'running',
  });

  factory ToolInvocation.fromJson(Map<String, dynamic> json) {
    return ToolInvocation(
      id: json['id']?.toString() ?? '',
      toolName: json['tool']?.toString() ?? json['name']?.toString() ?? 'tool',
      args: json['args'] is Map<String, dynamic> ? json['args'] : {},
      result: json['result'],
      status: json['status']?.toString() ?? 'completed',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tool': toolName,
      'args': args,
      'result': result,
      'status': status,
    };
  }
}

class ChatMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  String content;
  final DateTime timestamp;
  final List<ToolInvocation> toolCalls;
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    List<ToolInvocation>? toolCalls,
    this.isStreaming = false,
  }) : toolCalls = toolCalls ?? [];

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  String get text => content;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'tools': toolCalls.map((t) => t.toJson()).toList(),
      'is_streaming': isStreaming,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    var rawTools = json['tools'] ?? json['tool_calls'] ?? [];
    List<ToolInvocation> tools = [];
    if (rawTools is List) {
      tools = rawTools
          .whereType<Map<String, dynamic>>()
          .map((t) => ToolInvocation.fromJson(t))
          .toList();
    }

    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      toolCalls: tools,
      isStreaming: json['is_streaming'] == true,
    );
  }
}
