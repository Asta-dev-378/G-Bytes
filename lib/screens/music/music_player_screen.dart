import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/settings_provider.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  bool _sortAZ = false;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleAddFile(BuildContext context) async {
    final music = context.read<MusicProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      int addedCount = 0;
      for (final file in result.files) {
        MusicTrack? added;
        if (kIsWeb) {
          if (file.bytes != null) {
            added = await music.importFileBytes(
              fileName: file.name,
              bytes: file.bytes!,
            );
          }
        } else {
          if (file.path != null) {
            added = await music.importFile(
              sourcePath: file.path!,
              fileName: file.name,
            );
          }
        }
        if (added != null) addedCount++;
      }
      if (context.mounted && addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addedCount == 1
                  ? '"${result.files.first.name.replaceAll(RegExp(r'\.\w+$'), '')}" added!'
                  : '$addedCount tracks added!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF20BC68),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, MusicProvider music, int index) {
    final track = music.tracks[index];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              'Remove "${track.title}"?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'This will remove it from your G-Tunes library.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Keep',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      music.removeTrack(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile({
    required BuildContext ctx,
    required MusicProvider music,
    required int i,
    required MusicTrack t,
    required bool isCurrent,
    required Color tColor,
    required bool allowDrag,
  }) {
    final key = ValueKey('track_${i}_${t.title}');
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              'Remove',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(ctx, music, i);
        return false;
      },
      child: ListTile(
        key: ValueKey('tile_${i}_${t.title}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: CircleAvatar(
          backgroundColor: tColor.withValues(alpha: 0.15),
          child: Icon(
            t.storedPath != null
                ? Icons.audio_file_rounded
                : Icons.music_note_rounded,
            color: tColor,
            size: 18,
          ),
        ),
        title: Text(
          t.title,
          style: GoogleFonts.poppins(
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            color: isCurrent ? tColor : const Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          t.artist,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
        ),
        trailing: isCurrent
            ? _AnimatedMusicBars(
                color: tColor,
                isPlaying: music.isPlaying,
                size: 28,
              )
            : allowDrag
            ? ReorderableDragStartListener(
                index: i,
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              )
            : null,
        onTap: () => music.selectAndPlay(i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final settings = context.watch<SettingsProvider>();
    final track = music.current;
    final color = Color(music.colorValue);
    final themeColor = settings.appSeedColor;

    if (music.isPlaying) {
      if (!_rotateCtrl.isAnimating) _rotateCtrl.repeat();
    } else {
      _rotateCtrl.stop();
    }

    // Build filtered list with original index preserved
    final filtered = music.tracks.asMap().entries.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.value.title.toLowerCase().contains(_searchQuery) ||
          e.value.artist.toLowerCase().contains(_searchQuery);
    }).toList();
    if (_sortAZ) {
      filtered.sort((a, b) => a.value.title.compareTo(b.value.title));
    }

    // Reorder available only when full list shown in added order
    final canReorder = !_sortAZ && _searchQuery.isEmpty;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor.withValues(alpha: 0.15),
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'G-Tunes',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleAddFile(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: themeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Add Music',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main Content Area ─────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren.map((w) => Positioned.fill(child: w)),
                        if (currentChild != null) Positioned.fill(child: currentChild),
                      ],
                    );
                  },
                  child: track == null
                      ? Column(
                          key: const ValueKey('empty_state'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_music_rounded,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Your library is empty',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Add Music" to import songs\nfrom your device',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('player_state'),
                          children: [
                            const Spacer(),

                            // ── Album Art ─────────────────────────────────────────
                            RotationTransition(
                              turns: _rotateCtrl,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [color.withValues(alpha: 0.8), color],
                                    center: const Alignment(-0.3, -0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    track.storedPath != null
                                        ? Icons.audio_file_rounded
                                        : Icons.music_note_rounded,
                                    size: 72,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Track Info ────────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                children: [
                                  Text(
                                    track.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${track.artist} — ${track.album}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Progress Slider ───────────────────────────────────
                            StreamBuilder<Duration>(
                              stream: music.positionStream,
                              builder: (context, snap) {
                                final pos = snap.data ?? music.position;
                                final dur = music.duration;
                                final progress = dur.inSeconds > 0
                                    ? (pos.inSeconds / dur.inSeconds).clamp(0.0, 1.0)
                                    : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: color,
                                          inactiveTrackColor: Colors.grey.shade200,
                                          thumbColor: color,
                                          thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 7,
                                          ),
                                          overlayShape: SliderComponentShape.noOverlay,
                                        ),
                                        child: Slider(
                                          value: progress,
                                          onChanged: (v) => music.seekTo(
                                            Duration(seconds: (v * dur.inSeconds).round()),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _fmt(pos),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            Text(
                                              _fmt(dur),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // ── Playback Controls ─────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: music.toggleShuffle,
                                    icon: Icon(
                                      Icons.shuffle_rounded,
                                      color: music.isShuffle ? color : Colors.grey.shade400,
                                      size: 26,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: music.previous,
                                    icon: const Icon(Icons.skip_previous_rounded, size: 40),
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  GestureDetector(
                                    onTap: music.togglePlay,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        music.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: music.next,
                                    icon: const Icon(Icons.skip_next_rounded, size: 40),
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  IconButton(
                                    onPressed: music.toggleRepeat,
                                    icon: Icon(
                                      music.isRepeat
                                          ? Icons.repeat_one_rounded
                                          : Icons.repeat_rounded,
                                      color: music.isRepeat ? color : Colors.grey.shade400,
                                      size: 26,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // ── Library Panel ─────────────────────────────────────
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 20,
                                    offset: Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Library',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${filtered.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Search toggle
                                        IconButton(
                                          onPressed: () => setState(() {
                                            _showSearch = !_showSearch;
                                            if (!_showSearch) _searchCtrl.clear();
                                          }),
                                          icon: Icon(
                                            _showSearch
                                                ? Icons.search_off_rounded
                                                : Icons.search_rounded,
                                            color: _showSearch
                                                ? color
                                                : Colors.grey.shade500,
                                            size: 22,
                                          ),
                                          tooltip: 'Search',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 4),
                                        // Sort A→Z toggle
                                        IconButton(
                                          onPressed: () =>
                                              setState(() => _sortAZ = !_sortAZ),
                                          icon: Icon(
                                            Icons.sort_by_alpha_rounded,
                                            color: _sortAZ ? color : Colors.grey.shade500,
                                            size: 22,
                                          ),
                                          tooltip: _sortAZ ? 'Sort: A→Z' : 'Sort: Added',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),

                                  // Search bar (animated)
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    child: _showSearch
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              8,
                                            ),
                                            child: TextField(
                                              controller: _searchCtrl,
                                              autofocus: true,
                                              style: GoogleFonts.poppins(fontSize: 13),
                                              decoration: InputDecoration(
                                                hintText: 'Search songs…',
                                                hintStyle: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade400,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  color: Colors.grey.shade400,
                                                  size: 18,
                                                ),
                                                suffixIcon: _searchQuery.isNotEmpty
                                                    ? IconButton(
                                                        icon: const Icon(
                                                          Icons.close_rounded,
                                                        ),
                                                        onPressed: _searchCtrl.clear,
                                                        iconSize: 16,
                                                      )
                                                    : null,
                                                filled: true,
                                                fillColor: Colors.grey.shade100,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),

                                  // ── Track list ──────────────────────────────────
                                  SizedBox(
                                    height: 220,
                                    child: filtered.isEmpty
                                        ? Center(
                                            child: Text(
                                              _searchQuery.isEmpty
                                                  ? 'No music yet — tap Add Music above'
                                                  : 'No results for "$_searchQuery"',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey.shade400,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : canReorder
                                        // ── ReorderableListView: full list ──
                                        ? ReorderableListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            itemCount: music.tracks.length,
                                            onReorder: music.reorderTracks,
                                            buildDefaultDragHandles: false,
                                            proxyDecorator: (child, index, animation) =>
                                                Material(
                                                  elevation: 8,
                                                  borderRadius: BorderRadius.circular(14),
                                                  shadowColor: color.withValues(alpha: 0.3),
                                                  child: child,
                                                ),
                                            itemBuilder: (ctx2, i) {
                                              final t = music.tracks[i];
                                              return _buildTrackTile(
                                                ctx: ctx2,
                                                music: music,
                                                i: i,
                                                t: t,
                                                isCurrent: i == music.currentIndex,
                                                tColor: Color(t.colorValue),
                                                allowDrag: true,
                                              );
                                            },
                                          )
                                        // ── ListView: filtered/sorted ────────
                                        : ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            itemCount: filtered.length,
                                            itemBuilder: (ctx2, i) {
                                              final oi = filtered[i].key;
                                              final t = filtered[i].value;
                                              return _buildTrackTile(
                                                ctx: ctx2,
                                                music: music,
                                                i: oi,
                                                t: t,
                                                isCurrent: oi == music.currentIndex,
                                                tColor: Color(t.colorValue),
                                                allowDrag: false,
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated Music Bars ───────────────────────────────────────────────────
class _AnimatedMusicBars extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  final double size;

  const _AnimatedMusicBars({
    required this.color,
    required this.isPlaying,
    this.size = 30,
  });

  @override
  State<_AnimatedMusicBars> createState() => _AnimatedMusicBarsState();
}

class _AnimatedMusicBarsState extends State<_AnimatedMusicBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  static const int _barCount = 5;
  static const List<Color> _barColors = [
    Color(0xFFFF4081),
    Color(0xFFFF8C00),
    Color(0xFFFFD600),
    Color(0xFF00E5FF),
    Color(0xFF7C4DFF),
  ];
  static const List<int> _durations = [380, 520, 450, 600, 410];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _barCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      ),
    );
    _animations = List.generate(
      _barCount,
      (i) => Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      ),
    );
    _syncPlayState();
  }

  void _syncPlayState() {
    for (int i = 0; i < _barCount; i++) {
      if (widget.isPlaying) {
        _controllers[i].repeat(reverse: true);
      } else {
        _controllers[i].stop();
      }
    }
  }

  @override
  void didUpdateWidget(_AnimatedMusicBars old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) _syncPlayState();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(_controllers),
        builder: (_, _) => CustomPaint(
          painter: _MusicBarsPainter(
            barHeights: _animations.map((a) => a.value).toList(),
            barColors: _barColors,
            isPlaying: widget.isPlaying,
          ),
        ),
      ),
    );
  }
}

class _MusicBarsPainter extends CustomPainter {
  final List<double> barHeights;
  final List<Color> barColors;
  final bool isPlaying;

  _MusicBarsPainter({
    required this.barHeights,
    required this.barColors,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = barHeights.length;
    final barWidth = (size.width - (barCount - 1) * 2) / barCount;
    for (int i = 0; i < barCount; i++) {
      final height = size.height * barHeights[i];
      final x = i * (barWidth + 2);
      final y = size.height - height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(3),
        ),
        Paint()
          ..color = barColors[i]
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MusicBarsPainter old) =>
      old.barHeights != barHeights || old.isPlaying != isPlaying;
}
