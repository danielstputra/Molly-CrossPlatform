import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/molly_local_database.dart';
import '../../core/engine/molly_agent_engine.dart';
import '../../core/engine/molly_knowledge_engine.dart';
import '../../core/engine/molly_workspace_engine.dart';
import '../../core/models/agent_preset.dart';
import '../../core/models/chat_message.dart';
import '../../core/models/session.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/molly_background_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/molly_toast.dart';
import 'message_bubble.dart';
import 'session_drawer.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onOpenModulePicker;
  final AgentPreset? initialAgent;

  const ChatScreen({
    super.key,
    this.onOpenModulePicker,
    this.initialAgent,
  });

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _db = MollyLocalDatabase.instance;
  final _engine = MollyAgentEngine.instance;
  final _storage = LocalStorageService.instance;

  List<ChatSession> _sessions = [];
  String _currentSessionId = 'session-main';
  String _selectedAgentId = 'systematic-debugging-agent';
  String _selectedAgentName = 'Systematic Debugging';
  String _selectedModelName = 'gemini-3.8-flash-medium';
  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  StreamSubscription<String>? _activeStreamSubscription;

  void selectAgent(AgentPreset agent) {
    setState(() {
      _selectedAgentId = agent.id;
      _selectedAgentName = agent.name;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialAgent != null) {
      _selectedAgentId = widget.initialAgent!.id;
      _selectedAgentName = widget.initialAgent!.name;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _storage.init();
    final model = _storage.getActiveModel();
    if (model.isNotEmpty) {
      _selectedModelName = model;
    }
    await _loadLocalDatabaseSessions();
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

  void _handleSend([String? presetText]) {
    final text = (presetText ?? _textController.text).trim();
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

    // Dapatkan nama agen aktif
    final agentName = _agents.firstWhere(
      (a) => a.id == _selectedAgentId,
      orElse: () => _agents.isNotEmpty ? _agents.first : AgentPreset(
        id: 'agent-executive',
        name: 'Molly Executive',
        role: 'Chief AI Coordinator',
        systemPrompt: '',
        capabilities: [],
        colorHex: '0xFFF59E0B',
      ),
    ).name;

    // Aktifkan Background Task & WakeLock agar proses tidak mati saat diminimize
    unawaited(MollyBackgroundService.instance.startAgentTask(
      agentName: agentName,
      prompt: text,
    ));

    // Execute full agent loop & direct LLM streaming on device
    _activeStreamSubscription = _engine
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

        // Jika HP sedang di background / minimize dan tool dipanggil, kirim notifikasi konfirmasi / aktivitas
        if (MollyBackgroundService.instance.isAppInBackground) {
          unawaited(MollyBackgroundService.instance.notifyConfirmationRequired(
            agentName: agentName,
            actionDescription: 'Agen sedang mengeksekusi tool [${tool.toolName}]. Ketuk untuk meninjau.',
          ));
        }
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
        _activeStreamSubscription = null;
        _scrollToBottom();

        // Kirim Notifikasi Sukses ke status bar HP & release WakeLock
        unawaited(MollyBackgroundService.instance.notifyTaskSuccess(
          agentName: agentName,
          summary: botMsg.content,
        ));
        unawaited(MollyBackgroundService.instance.stopAgentTask());
      },
      onError: (err) {
        setState(() {
          botMsg.content += '\n\n*(Kendala On-Device Engine: $err)*';
          botMsg.isStreaming = false;
          _isGenerating = false;
        });
        _activeStreamSubscription = null;

        // Kirim Notifikasi Gagal ke status bar HP & release WakeLock
        unawaited(MollyBackgroundService.instance.notifyTaskFailed(
          agentName: agentName,
          errorMessage: err.toString(),
        ));
        unawaited(MollyBackgroundService.instance.stopAgentTask());
      },
    );
  }

  void _stopGeneration() {
    _activeStreamSubscription?.cancel();
    _activeStreamSubscription = null;
    unawaited(MollyBackgroundService.instance.stopAgentTask());
    setState(() {
      _isGenerating = false;
      if (_messages.isNotEmpty && _messages.last.isStreaming) {
        _messages.last.isStreaming = false;
      }
    });
    HapticFeedback.heavyImpact();
    MollyToast.showInfo(context, 'Streaming respons dihentikan.');
  }

  void _regenerateLatestResponse() {
    if (_isGenerating || _messages.isEmpty) return;
    String? lastUserPrompt;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        lastUserPrompt = _messages[i].content;
        break;
      }
    }
    if (lastUserPrompt == null || lastUserPrompt.isEmpty) return;

    if (_messages.last.role == 'assistant') {
      _messages.removeLast();
    }
    _handleSend(lastUserPrompt);
  }

  void _createNewSession() async {
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
        onRenameSession: (id, newTitle) async {
          await _db.updateSessionTitle(id, newTitle);
          await _loadLocalDatabaseSessions();
        },
        onNewSession: _createNewSession,
      ),
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.sidebar_left, color: AppColors.gold, size: 20),
          tooltip: 'Riwayat Sesi',
          onPressed: () {
            HapticFeedback.lightImpact();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        titleWidget: GestureDetector(
          onTap: _showAgentModelPicker,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Molly AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '$_selectedAgentName • $_selectedModelName',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_down, size: 10, color: AppColors.gold),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (widget.onOpenModulePicker != null)
            IconButton(
              icon: const Icon(CupertinoIcons.square_grid_2x2, color: AppColors.gold, size: 20),
              tooltip: 'Menu Modul Molly',
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onOpenModulePicker!();
              },
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle, color: AppColors.gold, size: 20),
            tooltip: 'Sesi Baru',
            onPressed: () {
              HapticFeedback.lightImpact();
              _createNewSession();
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: AppColors.textTertiary, size: 18),
            tooltip: 'Bersihkan Pesan',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await _db.deleteSession(_currentSessionId);
              await _loadLocalDatabaseSessions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: _messages.length <= 1 ? 2 : _messages.length,
              itemBuilder: (context, index) {
                if (_messages.length <= 1 && index == 1) {
                  return _buildSuggestedPrompts();
                }
                final isLastAssistant = index == _messages.length - 1 && !_messages[index].isUser;
                return MessageBubble(
                  message: _messages[index],
                  onRegenerate: isLastAssistant && !_isGenerating ? _regenerateLatestResponse : null,
                );
              },
            ),
          ),
          _buildPromptInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    final prompts = [
      {
        'title': 'Audit & Debugging Kode',
        'desc': 'Analisis error memory leak dan async deadlock',
        'prompt': 'Tolong analisis kemungkinan error memori dan async concurrency issue dalam aplikasi Flutter/Dart.',
        'icon': CupertinoIcons.ant_fill,
      },
      {
        'title': 'Jalankan Python Lokal',
        'desc': 'Simulasi perhitungan matriks di On-Device Runner',
        'prompt': 'Tolong buatkan script Python perhitungan statistik array dan jalankan di engine lokal.',
        'icon': CupertinoIcons.hammer_fill,
      },
      {
        'title': 'Telusuri Knowledge RAG',
        'desc': 'Cari panduan arsitektur pada SQLite lokal',
        'prompt': 'Jelaskan konsep arsitektur Molly On-Device Database dan integrasi SQLite mandiri.',
        'icon': CupertinoIcons.doc_text_fill,
      },
      {
        'title': 'Otomasi aBridge',
        'desc': 'Uji haptic vibration dan status Android',
        'prompt': 'Jelaskan kemampuan modul aBridge Controller untuk otomasi perangkat Android langsung dari HP.',
        'icon': CupertinoIcons.device_phone_portrait,
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'SARAN INSTRUKSI CEPAT',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.38,
            ),
            itemCount: prompts.length,
            itemBuilder: (context, idx) {
              final item = prompts[idx];
              return InkWell(
                onTap: () => _handleSend(item['prompt'] as String),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(item['icon'] as IconData, size: 18, color: AppColors.gold),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInputBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 4,
        bottom: isKeyboardOpen ? 8 : (safeBottom > 0 ? safeBottom + 74 : 82),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Tombol Attachment (Berkas & RAG)
                IconButton(
                  icon: const Icon(CupertinoIcons.paperclip, color: AppColors.gold, size: 20),
                  tooltip: 'Sisipkan Berkas / Konteks RAG',
                  onPressed: _showAttachmentSheet,
                ),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Tanyakan apa saja kepada Molly...',
                      hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),

                // Tombol Mic Voice Input
                IconButton(
                  icon: const Icon(CupertinoIcons.mic_fill, color: AppColors.textTertiary, size: 19),
                  tooltip: 'Instruksi Suara',
                  onPressed: _showVoiceInputSheet,
                ),

                // Tombol Kirim / Stop
                GestureDetector(
                  onTap: _isGenerating ? _stopGeneration : () => _handleSend(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isGenerating ? null : AppColors.goldGradient,
                      color: _isGenerating ? const Color(0xFFEF4444) : null,
                    ),
                    child: Center(
                      child: _isGenerating
                          ? const Icon(CupertinoIcons.stop_fill, size: 16, color: Colors.white)
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

  void _showAttachmentSheet() async {
    HapticFeedback.lightImpact();
    final files = await MollyWorkspaceEngine.instance.listFiles();
    final datasets = await _db.getDatasets();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SISIPKAN KONTEKS KE PROMPT',
                  style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
                const SizedBox(height: 14),

                // Opsi Berkas Workspace
                const Text('Berkas dari Personal Workspace:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (files.isEmpty)
                  const Text('Belum ada berkas tersimpan di workspace.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12))
                else
                  ...files.map((f) {
                    final name = f['file_name']?.toString() ?? 'file';
                    final content = f['file_content']?.toString() ?? '';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(CupertinoIcons.doc_plaintext, color: AppColors.gold, size: 18),
                      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                      trailing: const Text('Sisipkan', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(ctx);
                        final ext = name.split('.').last;
                        final snippet = '\n\n```$ext\n$content\n```\n';
                        _textController.text = '${_textController.text}$snippet';
                      },
                    );
                  }),

                const Divider(color: AppColors.glassBorder, height: 24),

                // Opsi Knowledge Dataset
                const Text('Referensi Knowledge Base RAG:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (datasets.isEmpty)
                  const Text('Belum ada dataset RAG lokal.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12))
                else
                  ...datasets.map((d) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(CupertinoIcons.square_stack_3d_up_fill, color: AppColors.gold, size: 18),
                      title: Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text('${d.documentCount} dokumen', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                      trailing: const Text('Sisipkan RAG', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final chunks = await _db.getChunks(datasetId: d.id);
                        final chunkTexts = chunks.take(3).map((c) => c['chunk_text']?.toString() ?? '').where((t) => t.isNotEmpty).join('\n---\n');
                        final snippet = chunkTexts.isNotEmpty
                            ? '\n\n[Referensi Dokumen (${d.name})]:\n$chunkTexts\n'
                            : ' [Gunakan Referensi RAG: ${d.name}] ';
                        _textController.text = '${_textController.text}$snippet';
                        if (mounted) {
                          MollyToast.showSuccess(context, 'Konteks RAG "${d.name}" disisipkan!');
                        }
                      },
                    );
                  }),

                const Divider(color: AppColors.glassBorder, height: 24),

                // Opsi Tempel Clipboard & Template Python
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.doc_on_clipboard, color: AppColors.gold, size: 18),
                  title: const Text('Tempel Isi Clipboard', style: TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      _textController.text = '${_textController.text} ${data.text}';
                    }
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.hammer, color: AppColors.gold, size: 18),
                  title: const Text('Sisipkan Template Script Python', style: TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () {
                    Navigator.pop(ctx);
                    const tmpl = '\n```python\nimport math, json, random\n\ndef run_simulation():\n    data = [random.randint(1, 100) for _ in range(10)]\n    return {"mean": sum(data) / len(data), "items": data}\n\nprint(json.dumps(run_simulation(), indent=2))\n```\n';
                    _textController.text = '${_textController.text}$tmpl';
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVoiceInputSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.15),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.mic_fill, color: AppColors.gold, size: 30),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Molly Voice Recognition',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih prompt suara instan atau ucapkan perintah Anda:',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Tolong optimalkan algoritma query ini',
                  'Jelaskan arsitektur Molly Standalone',
                  'Jalankan benchmark performa RAG',
                  'Buat arsitektur Next.js & Clean Architecture',
                ].map((txt) {
                  return ActionChip(
                    backgroundColor: AppColors.surfaceElevated,
                    label: Text(txt, style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _textController.text = txt;
                      _handleSend();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAgentModelPicker() async {
    HapticFeedback.lightImpact();
    final agents = await _db.getAgents();
    final currentProvider = _storage.getActiveProvider();
    final currentModel = _storage.getActiveModel();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PILIH AGEN & MODEL AKTIF',
                      style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 14),

                    // Daftar Agen
                    const Text('Agen Keahlian Molly:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...agents.map((ag) {
                      final isSelected = ag.id == _selectedAgentId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: AppColors.gold.withOpacity(0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Icon(
                          isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.person_crop_circle,
                          color: isSelected ? AppColors.gold : AppColors.textTertiary,
                          size: 18,
                        ),
                        title: Text(
                          ag.name,
                          style: TextStyle(
                            color: isSelected ? AppColors.gold : Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          ag.category,
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedAgentId = ag.id;
                            _selectedAgentName = ag.name;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }),

                    const Divider(color: AppColors.glassBorder, height: 24),

                    // Model LLM Quick Switcher
                    const Text('Model LLM Aktif:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'gemini-3.8-flash-medium',
                        'gemini-3.8-pro',
                        'gpt-4o',
                        'claude-3-5-sonnet',
                        'llama-3.3-70b-versatile',
                      ].map((m) {
                        final isSelected = m == _selectedModelName;
                        return ChoiceChip(
                          label: Text(m, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
                          selected: isSelected,
                          selectedColor: AppColors.gold,
                          backgroundColor: AppColors.surfaceElevated,
                          onSelected: (_) async {
                            await _storage.setActiveModel(m);
                            setState(() {
                              _selectedModelName = m;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
