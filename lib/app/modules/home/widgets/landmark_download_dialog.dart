import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/tour_localizations.dart';
import '../../../data/services/offline_landmark_store.dart';
import '../../../data/services/tts_service.dart';

class LandmarkDownloadDialog extends StatefulWidget {
  final String landmarkId;
  final String name;
  final String language;
  final String voiceLocale;
  final OfflineLandmarkStore store;
  final ValueChanged<OfflineLandmark?> onEnter;

  const LandmarkDownloadDialog({
    super.key,
    required this.landmarkId,
    required this.name,
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
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(_saved?.landmark.name ?? widget.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_saved != null && _message == null)
              Text(
                _updateAvailable
                    ? 'Update available'.tourText
                    : 'Downloaded'.tourText,
              ),
            if (_message case final String message) Text(message),
            if (_busy)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: _progress),
              ),
            if (_hasVoice == false && (Platform.isAndroid || Platform.isIOS))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  Platform.isAndroid
                      ? 'Install an offline voice for this language in your phone’s text-to-speech settings. You can read the tour without it.'
                            .tourText
                      : 'Install a voice for this language in Settings → Accessibility → Spoken Content → Voices. You can read the tour without it.'
                            .tourText,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text('Close'.tourText),
        ),
        if (_saved != null)
          TextButton(
            onPressed: _busy ? null : () => _enter(null),
            child: Text('Open live tour'.tourText),
          ),
        OutlinedButton(
          onPressed: _busy || _loading ? null : _download,
          child: Text(
            _failed
                ? 'Retry'.tourText
                : _saved == null
                ? 'Download for offline use'.tourText
                : 'Update download'.tourText,
          ),
        ),
        FilledButton(
          onPressed: _busy || _loading ? null : () => _enter(_saved),
          child: Text('Enter landmark'.tourText),
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Downloaded landmarks'.tourText),
    content: SizedBox(
      width: 400,
      height: 250,
      child: FutureBuilder<List<OfflineLandmark>>(
        future: _downloads,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Could not open downloads.'.tourText);
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final packages = snapshot.data!;
          if (packages.isEmpty) {
            return Text('No landmarks downloaded in this language.'.tourText);
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final package in packages)
                ListTile(
                  title: Text(package.landmark.name),
                  subtitle: Text('Available offline'.tourText),
                  enabled: !_removing,
                  onTap: () => Navigator.pop(context, package),
                  trailing: IconButton(
                    tooltip: 'Remove download'.tourText,
                    onPressed: _removing ? null : () => _remove(package),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Close'.tourText),
      ),
    ],
  );
}
