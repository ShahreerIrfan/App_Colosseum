import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/tour_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/floor_definition.dart';
import '../../../data/models/landmark_marker_model.dart';
import '../../../data/models/landmark_overlay_model.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/tts_service.dart';

class LandmarkDownloadDialog extends StatefulWidget {
  final String landmarkId;
  final String name;
  final String? category;
  final String? imagePath;
  final String? thumbnailUrl;
  final String? description;
  final String language;
  final String voiceLocale;
  final OfflineLandmarkStore store;
  final ValueChanged<OfflineLandmark?> onEnter;

  const LandmarkDownloadDialog({
    super.key,
    required this.landmarkId,
    required this.name,
    this.category,
    this.imagePath,
    this.thumbnailUrl,
    this.description,
    required this.language,
    required this.voiceLocale,
    required this.store,
    required this.onEnter,
  });

  @override
  State<LandmarkDownloadDialog> createState() => _LandmarkDownloadDialogState();
}

class _LandmarkDownloadDialogState extends State<LandmarkDownloadDialog> {
  OfflineLandmark? _saved;
  bool _loading = true;
  bool _busy = false;
  bool _failed = false;
  bool _updateAvailable = false;
  bool? _hasVoice;
  double? _progress;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaved());
    unawaited(_checkVoice());
  }

  Future<void> _checkVoice() async {
    final voice = await TtsService.findOfflineVoice(widget.voiceLocale);
    if (mounted) setState(() => _hasVoice = voice != null);
  }

  Future<void> _loadSaved() async {
    try {
      final saved = await widget.store.get(widget.landmarkId, widget.language);
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _updateAvailable = saved?.needsAerialMap == true;
        _loading = false;
      });
      if (saved == null) return;
      final manifest = await widget.store.latestManifest();
      if (mounted && identical(saved, _saved)) {
        setState(() => _updateAvailable = saved.needsAerialMap || manifest != saved.manifest);
      }
    } catch (_) {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _failed = false;
      _progress = null;
      _message = 'Preparing download…'.tourText;
    });
    try {
      final package = await widget.store.prepare(
        widget.landmarkId,
        widget.language,
      );
      final size = await widget.store.estimateBytes(package);
      if (!mounted) return;
      final colors = context.colors;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Download for offline use'.tourText),
          content: Text(
            size == null
                ? 'The download size could not be estimated.'.tourText
                : 'Estimated download: {size} MB'.tourTextWith({
                    'size': (size / (1024 * 1024)).toStringAsFixed(1),
                  }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'.tourText),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.primaryForeground,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Download'.tourText),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (accepted != true) {
        setState(() => _message = null);
        return;
      }
      final saved = await widget.store.save(
        package,
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _message = 'Downloading…'.tourText;
            _progress = total == 0 ? null : completed / total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _updateAvailable = false;
        _message = 'Downloaded'.tourText;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _message = _saved == null
            ? 'Download failed. Check your connection and available storage.'
                  .tourText
            : 'Download failed. Your saved tour is still available.'.tourText;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enter(OfflineLandmark? package) {
    Navigator.pop(context);
    widget.onEnter(package);
  }

  String _resolveDefaultCategory(String id) {
    final norm = id.toLowerCase();
    if (norm.contains('colosseum')) return 'Flavian Amphitheatre';
    if (norm.contains('arch')) return 'Triumphal Arch';
    if (norm.contains('ludus')) return 'Gladiatorial School';
    if (norm.contains('forum')) return 'Ancient Civic Center';
    if (norm.contains('temple') || norm.contains('venus')) return 'Ancient Temple';
    return 'Classical Monument';
  }

  String _resolveDefaultDescription(String id) {
    final norm = id.toLowerCase();
    if (norm.contains('colosseum')) {
      return 'The iconic elliptical amphitheatre in the centre of Rome, the largest ever built.';
    }
    if (norm.contains('arch')) {
      return "Triumphal arch celebrating Emperor Constantine I's victory at the Battle of Milvian Bridge.";
    }
    if (norm.contains('ludus')) {
      return 'The largest gladiatorial training arena and barracks in ancient Rome, connected by tunnels to the Colosseum.';
    }
    if (norm.contains('forum')) {
      return 'The vibrant civic, political, religious and commercial epicenter of ancient Roman civilization.';
    }
    if (norm.contains('temple') || norm.contains('venus')) {
      return 'The largest known temple in ancient Rome, dedicated to Venus Felix and Roma Aeterna.';
    }
    return '';
  }

  String _resolveFallbackAsset(String id) {
    final norm = id.toLowerCase();
    if (norm.contains('arch')) return 'assets/logo/Arch of Constantine.png';
    if (norm.contains('ludus')) return 'assets/logo/Ludus Magnus.png';
    if (norm.contains('forum')) return 'assets/logo/Roman Forum.png';
    if (norm.contains('temple') || norm.contains('venus')) return 'assets/logo/Temple of Venus and Rome.png';
    return 'assets/logo/Colosseum.png';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    // Resolve landmark metadata
    final marker = LandmarkMarkerModel.all.firstWhereOrNull((m) => m.id == widget.landmarkId);
    final overlay = MapLandmarkOverlay.all.firstWhereOrNull((o) => o.id == widget.landmarkId);
    final category = widget.category ?? marker?.category ?? _resolveDefaultCategory(widget.landmarkId);
    final description = widget.description ?? overlay?.description ?? _saved?.landmark.description ?? _resolveDefaultDescription(widget.landmarkId);

    final floors = FloorDefinition.floorsForLandmark(widget.landmarkId);
    final floorCount = floors.isNotEmpty ? floors.length : 1;
    final totalStops = floors.isNotEmpty
        ? floors.fold<int>(0, (sum, f) => sum + f.stopsCount)
        : 0;

    return PopScope(
      canPop: !_busy,
      child: Dialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border.withValues(alpha: 0.6), width: 1),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner with Artwork & Close Button
                _buildHeader(context, colors),

                // Content Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Pill
                      if (category.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 10,
                            ),
                          ),
                        ),

                      // Landmark Title
                      Text(
                        _saved?.landmark.name ?? widget.name,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.foreground,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tour Stats Strip (Floors, Stops, Audio)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildStatChip(
                            context,
                            Icons.layers_outlined,
                            floorCount == 1 ? '1 Floor'.tourText : '$floorCount Floors'.tourText,
                          ),
                          if (totalStops > 0)
                            _buildStatChip(
                              context,
                              Icons.place_outlined,
                              '$totalStops Stops'.tourText,
                            ),
                          _buildStatChip(
                            context,
                            Icons.headphones_outlined,
                            'Audio Tour'.tourText,
                          ),
                        ],
                      ),

                      // Landmark Description
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            description,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.mutedForeground,
                              height: 1.4,
                              fontSize: 12.5,
                            ),
                          ),
                        ),

                      // Download Progress / Status / Warnings
                      if (_loading)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: colors.primary.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                            ),
                          ),
                        ),

                      if (_saved != null && !_busy && !_failed)
                        _buildStatusBadge(context, colors),

                      if (_busy)
                        _buildProgressSection(context, colors),

                      if (_failed)
                        _buildFailedSection(context, colors),

                      if (_hasVoice == false && (Platform.isAndroid || Platform.isIOS))
                        _buildVoiceWarning(context, colors),

                      const SizedBox(height: 20),

                      // Action Buttons
                      _buildActionButtons(context, colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors colors) {
    final fallbackAsset = _resolveFallbackAsset(widget.landmarkId);
    final asset = widget.imagePath ?? fallbackAsset;
    final isNetwork = asset.startsWith('http://') || asset.startsWith('https://');

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Landmark Artwork
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: isNetwork
                ? Image.network(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.asset(
                      fallbackAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.account_balance_rounded,
                        size: 48,
                        color: colors.primary,
                      ),
                    ),
                  )
                : Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.account_balance_rounded,
                      size: 48,
                      color: colors.primary,
                    ),
                  ),
          ),

          // Top-right Close Button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: colors.card.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: colors.foreground),
                tooltip: 'Close'.tourText,
                onPressed: _busy ? null : () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.mutedForeground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AppColors colors) {
    final isUpdate = _updateAvailable;
    final color = isUpdate ? const Color(0xFFD97706) : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUpdate ? Icons.info_outline_rounded : Icons.check_circle_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isUpdate ? 'Update available'.tourText : 'Downloaded & ready offline'.tourText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, AppColors colors) {
    final textTheme = context.textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _message ?? 'Downloading…'.tourText,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              if (_progress != null)
                Text(
                  '${((_progress ?? 0) * 100).toInt()}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedSection(BuildContext context, AppColors colors) {
    final textTheme = context.textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.destructive.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: colors.destructive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message ?? 'Download failed.'.tourText,
              style: textTheme.bodySmall?.copyWith(color: colors.destructive, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWarning(BuildContext context, AppColors colors) {
    final textTheme = context.textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volume_off_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Platform.isAndroid
                  ? 'Install an offline voice for this language in your phone’s text-to-speech settings. You can read the tour without it.'.tourText
                  : 'Install a voice for this language in Settings → Accessibility → Spoken Content → Voices. You can read the tour without it.'.tourText,
              style: textTheme.bodySmall?.copyWith(fontSize: 11, color: const Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: Enter landmark
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            key: const Key('landmark_dialog_enter_button'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.primaryForeground,
              elevation: 2,
              shadowColor: colors.primary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _busy || _loading ? null : () => _enter(_saved),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              'Enter landmark'.tourText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary: Download for offline use / Update download / Retry
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            key: const Key('landmark_dialog_download_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(
                color: colors.primary.withValues(alpha: 0.45),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _busy || _loading ? null : _download,
            icon: Icon(
              _failed
                  ? Icons.refresh_rounded
                  : (_saved == null ? Icons.cloud_download_outlined : Icons.sync_rounded),
              size: 18,
            ),
            label: Text(
              _failed
                  ? 'Retry'.tourText
                  : _saved == null
                      ? 'Download for offline use'.tourText
                      : 'Update download'.tourText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ),

        // Live tour option (if saved)
        if (_saved != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: TextButton(
                onPressed: _busy ? null : () => _enter(null),
                child: Text(
                  'Open live tour'.tourText,
                  style: TextStyle(
                    color: colors.primary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

        // Close button for accessibility and tests
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(
            child: TextButton(
              key: const Key('landmark_dialog_close_button'),
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(
                'Close'.tourText,
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SavedLandmarkDownloads extends StatefulWidget {
  final String language;
  final OfflineLandmarkStore store;

  const SavedLandmarkDownloads({
    super.key,
    required this.language,
    required this.store,
  });

  @override
  State<SavedLandmarkDownloads> createState() => _SavedLandmarkDownloadsState();
}

class _SavedLandmarkDownloadsState extends State<SavedLandmarkDownloads> {
  late Future<List<OfflineLandmark>> _downloads = widget.store.list(
    widget.language,
  );
  bool _removing = false;

  Future<void> _remove(OfflineLandmark package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove download?'.tourText),
        content: Text(package.landmark.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tourText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'.tourText),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removing = true);
    try {
      await widget.store.remove(package);
      if (mounted) {
        setState(() => _downloads = widget.store.list(widget.language));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove the download.'.tourText)),
        );
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.download_done_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Downloaded landmarks'.tourText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: FutureBuilder<List<OfflineLandmark>>(
                  future: _downloads,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Could not open downloads.'.tourText));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final packages = snapshot.data!;
                    if (packages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No landmarks downloaded in this language.'.tourText,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: packages.length,
                      separatorBuilder: (_, _) => Divider(color: colors.border.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final package = packages[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            package.landmark.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Available offline'.tourText,
                            style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12),
                          ),
                          enabled: !_removing,
                          onTap: () => Navigator.pop(context, package),
                          trailing: IconButton(
                            tooltip: 'Remove download'.tourText,
                            onPressed: _removing ? null : () => _remove(package),
                            icon: Icon(Icons.delete_outline, color: colors.destructive),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'.tourText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
