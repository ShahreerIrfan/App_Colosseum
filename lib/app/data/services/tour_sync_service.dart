import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../models/tour_bundle_model.dart';
import '../repositories/i_tour_repository.dart';
import '../repositories/tour_repository_impl.dart';
import 'offline_landmark_store.dart';

/// Publishes one committed tour snapshot to every live screen.
class TourSyncService extends GetxService with WidgetsBindingObserver {
  static const interval = Duration(minutes: 5);
  static const retryDelay = Duration(seconds: 30);

  TourSyncService(this.repository, this.downloads, {Connectivity? connectivity})
    : connectivity = connectivity ?? Connectivity();

  final TourRepositoryImpl repository;
  final OfflineLandmarkStore downloads;
  final Connectivity connectivity;
  final _snapshots = StreamController<TourBundleModel>.broadcast(sync: true);
  final _running = <String, Future<TourSyncResult>>{};
  final _confirmed = <String>{};
  StreamSubscription<List<ConnectivityResult>>? _connection;
  Timer? _poll;
  Timer? _retry;
  String? _language;
  TourBundleModel? _snapshot;
  bool _foreground = true;
  bool _closed = false;
  bool _updatingDownloads = false;
  List<ConnectivityResult> _networks = const [];

  Stream<TourBundleModel> get snapshots => _snapshots.stream;
  TourBundleModel? snapshotFor(String language) =>
      _language == language ? _snapshot : null;

  @override
  void onInit() {
    super.onInit();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _connection = connectivity.onConnectivityChanged.listen(
      _onConnection,
      onError: (Object _) {},
    );
    unawaited(_readConnection());
    _startPolling();
  }

  Future<void> _readConnection() async {
    try {
      _onConnection(await connectivity.checkConnectivity());
    } catch (_) {}
  }

  void _onConnection(List<ConnectivityResult> results) {
    final previous = _networks.toSet();
    _networks = results;
    final connected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (_foreground &&
        connected &&
        (previous.length != results.length || !previous.containsAll(results))) {
      unawaited(check());
    }
  }

  void _startPolling() {
    _poll?.cancel();
    if (_foreground) {
      _poll = Timer.periodic(interval, (_) => unawaited(check()));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _foreground;
    _foreground = state == AppLifecycleState.resumed;
    if (wasForeground == _foreground) return;
    _startPolling();
    if (_foreground) {
      unawaited(_readConnection());
      unawaited(check());
    } else {
      _retry?.cancel();
    }
  }

  Future<TourSyncResult> activate(String language) async {
    if (_language == language) {
      return _running[language] ??
          (_snapshot == null
              ? check()
              : Future.value(TourSyncResult.unchanged));
    }
    _language = language;
    _snapshot = null;
    return check();
  }

  Future<TourSyncResult> check({bool force = false}) {
    final language = _language;
    if (language == null || !_foreground || _closed) {
      return Future.value(TourSyncResult.unavailable);
    }
    return _running.putIfAbsent(language, () async {
      try {
        if (_snapshot == null) {
          _publish(
            language,
            await repository.localDataSource.getCachedTourBundle(
              lang: language,
              allowSeed: true,
            ),
          );
        }
        // Revalidate legacy installs once even if their cached version matches.
        final result = await repository.refreshTourBundle(
          lang: language,
          force: force || !_confirmed.contains(language),
        );
        if (_closed || _language != language) return result;
        _retry?.cancel();
        if (result == TourSyncResult.unavailable) {
          if (_foreground) _retry = Timer(retryDelay, () => unawaited(check()));
          return result;
        }
        _confirmed.add(language);
        if (result == TourSyncResult.updated || _snapshot == null) {
          _publish(
            language,
            await repository.localDataSource.getCachedTourBundle(
              lang: language,
            ),
          );
        }
        final snapshot = snapshotFor(language);
        if (snapshot != null && _networks.contains(ConnectivityResult.wifi)) {
          unawaited(_refreshDownloads(language, snapshot));
        }
        return result;
      } catch (_) {
        if (!_closed && _foreground && _language == language) {
          _retry?.cancel();
          _retry = Timer(retryDelay, () => unawaited(check()));
        }
        return TourSyncResult.unavailable;
      } finally {
        _running.remove(language);
      }
    });
  }

  void _publish(String language, TourBundleModel? snapshot) {
    if (_closed || _language != language || snapshot == null) return;
    _snapshot = snapshot;
    _snapshots.add(snapshot);
  }

  Future<void> _refreshDownloads(
    String language,
    TourBundleModel snapshot,
  ) async {
    if (_updatingDownloads) return;
    _updatingDownloads = true;
    try {
      final published = snapshot.landmarks
          .map((landmark) => landmark.id)
          .toSet();
      for (final saved in await downloads.list(language)) {
        if (_closed ||
            !_foreground ||
            _language != language ||
            !_networks.contains(ConnectivityResult.wifi)) {
          break;
        }
        final id = saved.landmark.id;
        if ((saved.manifest == snapshot.manifest && !saved.needsAerialMap) ||
            !published.contains(id)) {
          continue;
        }
        try {
          await downloads.refreshSaved(
            saved,
            canContinue: () =>
                !_closed &&
                _foreground &&
                _language == language &&
                _networks.contains(ConnectivityResult.wifi),
          );
        } catch (_) {
          // An interrupted update leaves the previous download available.
        }
      }
    } catch (_) {
      // Storage errors must not prevent the live tour from updating.
    } finally {
      _updatingDownloads = false;
    }
  }

  @override
  void onClose() {
    if (_closed) return;
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _retry?.cancel();
    unawaited(_connection?.cancel());
    unawaited(_snapshots.close());
    super.onClose();
  }
}
