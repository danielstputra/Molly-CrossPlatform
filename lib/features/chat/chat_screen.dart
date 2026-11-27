import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_agent_engine.dart';
import '../../core/models/chat_message.dart';
import '../../core/models/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_app_bar.dart';
import 'message_bubble.dart';
import 'session_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _db = MollyLocalDatabase.instance;
  final _engine = MollyAgentEngine.instance;

  List<ChatSession> _sessions = [];
  String _currentSessionId = 'session-main';
  final String _selectedAgentId = 'systematic-debugging-agent';
  List<ChatMessage> _messages = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadLocalDatabaseSessions();
  }

  Future<void> _loadLocalDatabaseSessions() async {
    final list = await _db.getSessions();
    if (list.isEmpty) {
      final defaultSession = ChatSession(
        id: 'session-main',
        title: 'Molly Standalone On-Device',
        updatedAt: DateTime.now(),
      );
      await _db.saveSession(defaultSession);
      _sessions = [defaultSession];
    } else {
      _sessions = list;
    }

    _currentSessionId = _sessions.first.id;
    final msgs = await _db.getMessages(_currentSessionId);

    if (mounted) {
      setState(() {
        _messages = msgs.isNotEmpty
            ? msgs
            : [
                ChatMessage(
                  id: 'welcome',
                  role: 'assistant',
                  content:
                      'Halo! Saya **Molly AI On-Device Engine**.\n\nSistem ini beroperasi **100% mandiri** dengan **Database SQLite Lokal** langsung di memori HP Anda tanpa perantara server backend.\n\nAda yang bisa saya bantu untuk koding, arsitektur, atau otomasi tugas hari ini?',
                  timestamp: DateTime.now(),
                )
              ];
      });
    }
  }

  Future<void> _switchSession(String sessionId) async {
    final msgs = await _db.getMessages(sessionId);
    setState(() {
      _currentSessionId = sessionId;
      _messages = msgs.isNotEmpty
          ? msgs
          : [
              ChatMessage(
                id: 'welcome-$sessionId',
                role: 'assistant',
                content: 'Sesi baru lokal dibuka. Tanyakan apa saja kepada Molly.',
                timestamp: DateTime.now(),
              )
            ];
    });
  }

  Future<void> _deleteSession(String sessionId) async {
    await _db.deleteSession(sessionId);
    final list = await _db.getSessions();
    if (list.isEmpty) {
      await _loadLocalDatabaseSessions();
    } else {
      _sessions = list;
      await _switchSession(list.first.id);
    }
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    HapticFeedback.mediumImpact();
    _textController.clear();

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    final botMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch + 1}',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(botMsg);
      _isGenerating = true;
    });

    _scrollToBottom();

    // Execute full agent loop & direct LLM streaming on device
    _engine
        .executeAgentStream(
      sessionId: _currentSessionId,
      userPrompt: text,
      agentId: _selectedAgentId,
      onToolCall: (tool) {
        setState(() {
          if (!botMsg.toolCalls.any((t) => t.id == tool.id)) {
            botMsg.toolCalls.add(tool);
          }
        });
      },
    )
        .listen(
      (chunk) {
        setState(() {
          botMsg.content += chunk;
        });
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          botMsg.isStreaming = false;
          _isGenerating = false;
        });
        _scrollToBottom();
      },
      onError: (err) {
        setState(() {
          botMsg.content += '\n\n*(Kendala On-Device Engine: $err)*';
          botMsg.isStreaming = false;
          _isGenerating = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: SessionDrawer(
        sessions: _sessions,
        currentSessionId: _currentSessionId,
        onSelectSession: (id) => _switchSession(id),
        onDeleteSession: (id) => _deleteSession(id),
        onNewSession: () async {
          final newId = 'session-${DateTime.now().millisecondsSinceEpoch}';
          final newSession = ChatSession(
            id: newId,
            title: 'Sesi Baru (${_sessions.length + 1})',
            updatedAt: DateTime.now(),
          );
          await _db.saveSession(newSession);
          setState(() {
            _sessions.insert(0, newSession);
            _currentSessionId = newId;
            _messages = [
              ChatMessage(
                id: 'welcome-$newId',
                role: 'assistant',
                content: 'Sesi baru dibuka di SQLite lokal. Silakan ajukan pertanyaan Anda.',
                timestamp: DateTime.now(),
              )
            ];
          });
        },
      ),
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.sidebar_left, color: AppColors.gold, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: 'Molly Standalone',
        subtitle: 'On-Device SQLite Engine • Mandiri',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: AppColors.textTertiary, size: 18),
            tooltip: 'Hapus Pesan Sesi',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await _db.deleteSession(_currentSessionId);
              await _loadLocalDatabaseSessions();
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.35), width: 0.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.circle_filled, size: 9, color: Color(0xFF10B981)),
                SizedBox(width: 5),
                Text(
                  'SQLITE LOKAL',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 140,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _buildPromptInputBar(),
        ],
      ),
    );
  }

  Widget _buildPromptInputBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Container(
      margin: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 6,
        bottom: isKeyboardOpen ? 8 : 86,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.paperclip, color: AppColors.textTertiary, size: 20),
                  onPressed: () => HapticFeedback.lightImpact(),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Tanyakan apa saja kepada Molly Engine...',
                      hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isGenerating ? null : AppColors.goldGradient,
                      color: _isGenerating ? AppColors.surface : null,
                    ),
                    child: Center(
                      child: _isGenerating
                          ? const CupertinoActivityIndicator(radius: 8, color: AppColors.gold)
                          : const Icon(CupertinoIcons.arrow_up, size: 18, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
