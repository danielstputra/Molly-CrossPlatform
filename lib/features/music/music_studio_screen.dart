import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_decorations.dart';
import '../../core/widgets/glass_app_bar.dart';

class MusicTrack {
  final String id;
  final String title;
  final String genre;
  final String lyrics;
  final String duration;
  final bool isInstrumental;
  final DateTime createdAt;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.genre,
    required this.lyrics,
    required this.duration,
    required this.isInstrumental,
    required this.createdAt,
  });
}

class MusicStudioScreen extends StatefulWidget {
  const MusicStudioScreen({super.key});

  @override
  State<MusicStudioScreen> createState() => _MusicStudioScreenState();
}

class _MusicStudioScreenState extends State<MusicStudioScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();

  bool _isInstrumental = false;
  String _selectedGenre = 'Acoustic Pop';
  String _selectedModel = 'v6-mini';
  bool _isGenerating = false;

  // Active Playback State
  MusicTrack? _activePlayingTrack;
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  Timer? _playbackTimer;

  final List<String> _presetGenres = [
    'Acoustic Pop',
    'Lo-Fi Chill',
    'Cinematic Epic',
    'Indie Folk',
    'Synthwave 80s',
    'EDM Festival',
    'R&B Soul',
    'Piano Ballad',
    'Rock Anthem',
  ];

  final List<MusicTrack> _tracks = [
    MusicTrack(
      id: 'track-1',
      title: 'Midnight Code Symphony',
      genre: 'Lo-Fi Chill',
      lyrics: '[Verse 1]\nNeon glowing in the dark\nCursor blinking like a spark\n\n[Chorus]\nLines of code into the night\nEverything will be alright',
      duration: '02:45',
      isInstrumental: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MusicTrack(
      id: 'track-2',
      title: 'Cyberpunk Dawn',
      genre: 'Synthwave 80s',
      lyrics: '[Instrumental Synth Waves & Retro Basslines]',
      duration: '03:12',
      isInstrumental: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _promptController.dispose();
    _titleController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  void _generateTrack() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Lagu ${_selectedGenre} #${_tracks.length + 1}'
        : _titleController.text.trim();

    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final newTrack = MusicTrack(
      id: 'track-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      genre: _selectedGenre,
      lyrics: _lyricsController.text.trim().isNotEmpty
          ? _lyricsController.text.trim()
          : (_isInstrumental
              ? '[Instrumental Track]'
              : '[Verse 1]\nNada mengalun di malam hening\nLangkah terhenti di batas dingin\n\n[Chorus]\nBintang bersinar menuntun asa\nMolly melodi penuh pesona'),
      duration: '02:50',
      isInstrumental: _isInstrumental,
      createdAt: DateTime.now(),
    );

    setState(() {
      _tracks.insert(0, newTrack);
      _isGenerating = false;
      _titleController.clear();
      _promptController.clear();
      _lyricsController.clear();
    });

    _playTrack(newTrack);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lagu "$title" berhasil dibuat & siap diputar!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _playTrack(MusicTrack track) {
    _playbackTimer?.cancel();
    setState(() {
      _activePlayingTrack = track;
      _isPlaying = true;
      _playbackProgress = 0.0;
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _playbackProgress += 0.02;
        if (_playbackProgress >= 1.0) {
          _playbackProgress = 0.0;
          _isPlaying = false;
          t.cancel();
        }
      });
    });
  }

  void _togglePlayPause() {
    if (_activePlayingTrack == null && _tracks.isNotEmpty) {
      _playTrack(_tracks.first);
      return;
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (!mounted || !_isPlaying) {
          t.cancel();
          return;
        }
        setState(() {
          _playbackProgress += 0.02;
          if (_playbackProgress >= 1.0) {
            _playbackProgress = 0.0;
            _isPlaying = false;
            t.cancel();
          }
        });
      });
    } else {
      _playbackTimer?.cancel();
    }
  }

  void _insertLyricsTag(String tag) {
    final text = _lyricsController.text;
    final selection = _lyricsController.selection;
    final newText = text.replaceRange(
      selection.start >= 0 ? selection.start : text.length,
      selection.end >= 0 ? selection.end : text.length,
      '\n$tag\n',
    );
    _lyricsController.text = newText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlassAppBar(
        title: 'Suno AI Music Studio',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activePlayingTrack != null) ...[
              _buildActivePlayerBanner(),
              const SizedBox(height: 16),
            ],
            _buildGeneratorCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RIWAYAT LAGU SUNO AI (${_tracks.length})',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrackList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlayerBanner() {
    final track = _activePlayingTrack!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecorations.frostedCard(blur: 24, borderColor: AppColors.gold.withOpacity(0.5)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  track.isInstrumental ? CupertinoIcons.guitars : CupertinoIcons.music_note_2,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${track.genre} • ${track.duration}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                  color: AppColors.gold,
                  size: 38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _playbackProgress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlassDecorations.frostedCard(blur: 16, borderColor: AppColors.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'Buat Musik Baru dengan Suno AI',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Judul Lagu (Opsional)',
              labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Deskripsi / Ide Lagu (misal: Sunset drive with retro synth vibes)',
              labelStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Pilih Genre & Gaya:', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presetGenres.map((g) {
                final isSelected = _selectedGenre == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(g, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.surfaceElevated,
                    onSelected: (val) {
                      setState(() => _selectedGenre = g);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hanya Instrumental (Tanpa Vokal):', style: TextStyle(color: Colors.white, fontSize: 12.5)),
              CupertinoSwitch(
                value: _isInstrumental,
                activeColor: AppColors.gold,
                onChanged: (val) => setState(() => _isInstrumental = val),
              ),
            ],
          ),
          if (!_isInstrumental) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lirik Kustom (Opsional):', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                Row(
                  children: [
                    _tagBtn('[Verse]'),
                    const SizedBox(width: 4),
                    _tagBtn('[Chorus]'),
                    const SizedBox(width: 4),
                    _tagBtn('[Bridge]'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _lyricsController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Tulis lirik kustom atau biarkan kosong untuk di-generate otomatis oleh AI...',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateTrack,
              icon: _isGenerating
                  ? const CupertinoActivityIndicator(color: Colors.black, radius: 10)
                  : const Icon(CupertinoIcons.play_arrow_solid, color: Colors.black, size: 16),
              label: Text(
                _isGenerating ? 'Sedang Memproses Komposisi...' : 'Generate Musik dengan Suno AI',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagBtn(String tag) {
    return GestureDetector(
      onTap: () => _insertLyricsTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(tag, style: const TextStyle(color: AppColors.gold, fontSize: 9.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTrackList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        final isThisPlaying = _activePlayingTrack?.id == track.id && _isPlaying;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: GlassDecorations.frostedCard(
            blur: 16,
            borderColor: isThisPlaying ? AppColors.gold.withOpacity(0.5) : AppColors.glassBorder,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_activePlayingTrack?.id == track.id) {
                    _togglePlayPause();
                  } else {
                    _playTrack(track);
                  }
                },
                icon: Icon(
                  isThisPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${track.genre} • ${track.duration}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.doc_on_doc, color: AppColors.textTertiary, size: 16),
                tooltip: 'Salin Lirik',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: track.lyrics));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lirik berhasil disalin!'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
