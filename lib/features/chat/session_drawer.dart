import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/molly_text_field.dart';

/// Drawer sesi bergaya bilah samping (Sidebar) iPadOS / macOS dengan efek kaca frosted blur.
/// Mendukung pencarian instan, filter ruang proyek, penggantian judul (rename), dan penghapusan sesi.
class SessionDrawer extends StatefulWidget {
  final List<ChatSession> sessions;
  final String currentSessionId;
  final Function(String) onSelectSession;
  final VoidCallback onNewSession;
  final Function(String)? onDeleteSession;
  final Function(String, String)? onRenameSession;

  const SessionDrawer({
    super.key,
    required this.sessions,
    required this.currentSessionId,
    required this.onSelectSession,
    required this.onNewSession,
    this.onDeleteSession,
    this.onRenameSession,
  });

  @override
  State<SessionDrawer> createState() => _SessionDrawerState();
}

class _SessionDrawerState extends State<SessionDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedProject = 'Semua';

  final List<String> _projectFilters = ['Semua', 'Umum', 'Debugging', 'Mobile'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatSession> get _filteredSessions {
    return widget.sessions.where((session) {
      final matchesSearch = _searchQuery.isEmpty ||
          session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (session.lastMessage?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesSearch;
    }).toList();
  }

  void _showRenameDialog(ChatSession session) {
    final titleController = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder, width: 0.8),
          ),
          title: const Text(
            'Ubah Nama Percakapan',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          content: MollyTextField(
            controller: titleController,
            labelText: 'Judul Percakapan',
            hintText: 'Ketik judul sesi baru...',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textTertiary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final newTitle = titleController.text.trim();
                if (newTitle.isNotEmpty && widget.onRenameSession != null) {
                  widget.onRenameSession!(session.id, newTitle);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSessions;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            color: AppColors.bgPrimary.withOpacity(0.88),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Drawer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Riwayat Percakapan",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.square_pencil, color: AppColors.gold, size: 20),
                          tooltip: "Sesi Baru",
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            widget.onNewSession();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Search Bar Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder, width: 0.6),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(CupertinoIcons.search, size: 15, color: AppColors.textTertiary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(CupertinoIcons.clear_circled_solid, size: 14, color: AppColors.textTertiary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          hintText: 'Cari topik percakapan...',
                          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),

                  // Project Filter Tabs (Paritas Molly Web Projects)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _projectFilters.map((p) {
                          final isCurrent = _selectedProject == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                p,
                                style: TextStyle(
                                  color: isCurrent ? Colors.black : AppColors.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              selected: isCurrent,
                              selectedColor: AppColors.gold,
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: isCurrent ? AppColors.gold : AppColors.glassBorder,
                                width: 0.6,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _selectedProject = p),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const Divider(color: AppColors.borderGlass, height: 1),

                  // Daftar Sesi
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ditemukan sesi dengan kata kunci "$_searchQuery".'
                                    : 'Belum ada riwayat percakapan.',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 3),
                            itemBuilder: (context, index) {
                              final session = filtered[index];
                              final isSelected = session.id == widget.currentSessionId;

                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                selected: isSelected,
                                selectedTileColor: AppColors.goldGlow.withOpacity(0.18),
                                leading: Icon(
                                  CupertinoIcons.chat_bubble_fill,
                                  size: 15,
                                  color: isSelected ? AppColors.gold : AppColors.textMuted,
                                ),
                                title: Text(
                                  session.title,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.goldLight : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: session.lastMessage != null && session.lastMessage!.isNotEmpty
                                    ? Text(
                                        session.lastMessage!,
                                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 10.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.pencil, size: 14, color: AppColors.textTertiary),
                                      tooltip: 'Ubah Judul',
                                      onPressed: () => _showRenameDialog(session),
                                    ),
                                    if (widget.onDeleteSession != null && widget.sessions.length > 1)
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.trash, size: 14, color: AppColors.textTertiary),
                                        tooltip: 'Hapus Sesi',
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          widget.onDeleteSession!(session.id);
                                        },
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                  widget.onSelectSession(session.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
