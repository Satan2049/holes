import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/camera.dart';
import '../models/user_preferences.dart';
import '../services/blocklist_service.dart';
import '../services/camera_data_service.dart';
import '../services/content_filter_service.dart';
import '../services/favorites_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_sheet.dart';
import '../utils/platform_playback.dart';
import '../widgets/fullscreen_player_screen.dart';
import '../widgets/stream_player.dart';
import 'onboarding_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<Camera> _all = [];
  List<Camera> _filtered = [];
  UserPreferences _prefs = const UserPreferences();
  BrowseFilters _filters = const BrowseFilters();
  int _index = 0;
  bool _loading = true;
  String? _loadError;
  final _searchController = TextEditingController();
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await BlocklistService.instance.ensureLoaded();
      await FavoritesService.instance.ensureLoaded();
      final prefs = await PreferencesService().load();
      final all = await CameraDataService().loadAll();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _all = all;
        _loading = false;
        if (kIsWeb && !_filters.webFriendlyOnly) {
          _filters = _filters.copyWith(webFriendlyOnly: true);
        }
      });
      await _applyFilters(restoreLast: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
        _all = [];
        _filtered = [];
      });
    }
  }

  Future<void> _applyFilters({bool restoreLast = false}) async {
    final list = ContentFilterService().apply(
      all: _all,
      prefs: _prefs,
      active: _filters,
      isBlocked: BlocklistService.instance.isBlocked,
      favoriteIds: FavoritesService.instance.ids,
    );

    var index = _index;
    if (index >= list.length) {
      index = list.isEmpty ? 0 : list.length - 1;
    }

    if (restoreLast) {
      final lastId = await PreferencesService().loadLastCameraId();
      if (lastId != null) {
        final lastIdx = list.indexWhere((c) => c.id == lastId);
        if (lastIdx >= 0) index = lastIdx;
      }
    } else if (_current != null) {
      // Keep the same camera visible after filters change (e.g. skip & hide).
      final currentId = _current!.id;
      final sameIdx = list.indexWhere((c) => c.id == currentId);
      if (sameIdx >= 0) {
        index = sameIdx;
      } else if (index >= list.length) {
        index = list.isEmpty ? 0 : list.length - 1;
      }
    }

    if (!mounted) return;
    setState(() {
      _filtered = list;
      _index = index;
    });
    _rememberCurrentCamera();
  }

  void _rememberCurrentCamera() {
    final cam = _current;
    if (cam != null) {
      PreferencesService().saveLastCameraId(cam.id);
    }
  }

  Camera? get _current => _filtered.isEmpty ? null : _filtered[_index];

  bool get _isFavorite {
    final cam = _current;
    return cam != null && FavoritesService.instance.isFavorite(cam.id);
  }

  void _next() {
    if (_filtered.isEmpty || _filtered.length == 1) return;
    var next = _random.nextInt(_filtered.length);
    while (next == _index) {
      next = _random.nextInt(_filtered.length);
    }
    setState(() => _index = next);
    _rememberCurrentCamera();
  }

  void _previous() {
    if (_filtered.isEmpty) return;
    setState(() => _index = (_index - 1 + _filtered.length) % _filtered.length);
    _rememberCurrentCamera();
  }

  Future<void> _skipAndHide() async {
    final cam = _current;
    if (cam == null) return;
    BlocklistService.instance.blockSession(cam.id);
    await _applyFilters();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hidden: ${cam.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            BlocklistService.instance.unblockSession(cam.id);
            _applyFilters();
          },
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final cam = _current;
    if (cam == null) return;
    await FavoritesService.instance.toggle(cam.id);
    if (!mounted) return;
    setState(() {});
    if (_filters.favoritesOnly) await _applyFilters();
  }

  Future<void> _openInBrowser() async {
    final cam = _current;
    if (cam == null) return;
    final uri = Uri.parse(cam.streamUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openFullscreen() {
    final cam = _current;
    if (cam == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          camera: cam,
          autoplay: _prefs.autoplayStreams,
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<BrowseFilters>(
      context: context,
      backgroundColor: AppColors.void950,
      isScrollControlled: true,
      builder: (ctx) => FilterSheet(
        filters: _filters,
        countries: ContentFilterService.countries(_all),
        favoriteCount: FavoritesService.instance.ids.length,
      ),
    );
    if (result != null) {
      setState(() => _filters = result);
      await _applyFilters();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen(fromSettings: true)),
    );
    final prefs = await PreferencesService().load();
    if (!mounted) return;
    setState(() => _prefs = prefs);
    await _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _filters = BrowseFilters(webFriendlyOnly: kIsWeb);
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showHlsOnly() {
    setState(() => _filters = _filters.copyWith(streamTypeOnly: StreamType.hls));
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _filters = _filters.copyWith(query: ''));
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.void950,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 12),
              Text('Loading cameras…', style: TextStyle(color: AppColors.onSurfaceMuted)),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.void950,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load cameras', style: TextStyle(color: AppColors.onBackground)),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: const TextStyle(color: AppColors.cyber400, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadCameras,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final current = _current;
    final filterBits = <String>[
      if (_filters.favoritesOnly) 'favorites',
      if (_filters.webFriendlyOnly) 'web-friendly',
    ];

    return Scaffold(
      backgroundColor: AppColors.void950,
      body: SafeArea(
        child: Column(
          children: [
            if (PlatformPlayback.isWeb)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.void900,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  PlatformPlayback.webWarning,
                  style: const TextStyle(color: AppColors.cyber400, fontSize: 11, height: 1.35),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                '${_filtered.length} of ${_all.length} cameras'
                '${filterBits.isEmpty ? '' : ' (${filterBits.join(', ')})'}',
                style: const TextStyle(color: AppColors.cyber400, fontSize: 11),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.onBackground),
                decoration: InputDecoration(
                  hintText: 'Search name, city, country, tags…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceDim),
                  suffixIcon: _filters.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.cyber400),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
                onChanged: (v) {
                  setState(() => _filters = _filters.copyWith(query: v));
                  _applyFilters();
                },
              ),
            ),
            if (current != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        current.name,
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${_index + 1} / ${_filtered.length}',
                      style: const TextStyle(color: AppColors.cyber400, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${current.locationLabel} · ${current.category.name}',
                    style: const TextStyle(color: AppColors.cyber400, fontSize: 12),
                  ),
                ),
              ),
              if (current.attributionLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Source: ${current.attributionLabel}',
                      style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
            Expanded(
              child: current == null
                  ? _emptyState()
                  : StreamPlayer(
                      key: ValueKey(current.id),
                      camera: current,
                      autoplay: _prefs.autoplayStreams,
                      onSkipAndHide: _skipAndHide,
                    ),
            ),
            _controlsBar(),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    final filteredOut = _all.isNotEmpty && _filtered.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filteredOut ? Icons.filter_alt : Icons.videocam_off,
              color: AppColors.onSurfaceMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              filteredOut ? 'No cameras match your filters' : 'No cameras in data file',
              style: const TextStyle(color: AppColors.onBackground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              filteredOut
                  ? 'Try clearing filters or showing HLS-only streams. $_all cameras in bundled data.'
                  : 'Add entries to assets/data/*.json then full restart.',
              style: const TextStyle(color: AppColors.cyber400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (filteredOut) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (_filters.query.trim().isNotEmpty)
                    ActionChip(
                      label: const Text('Clear search'),
                      onPressed: _clearSearch,
                    ),
                  if (_filters.hasActiveFilters)
                    ActionChip(
                      label: const Text('Clear filters'),
                      onPressed: _clearFilters,
                    ),
                  ActionChip(
                    label: const Text('HLS only'),
                    onPressed: _showHlsOnly,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _openSettings,
                child: const Text('Open content settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _controlsBar() {
    final hasCams = _filtered.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      decoration: const BoxDecoration(
        color: AppColors.void900,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous',
            onPressed: hasCams ? _previous : null,
            icon: const Icon(Icons.skip_previous, color: AppColors.onBackground, size: 28),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Random next',
            onPressed: hasCams && _filtered.length > 1 ? _next : null,
            icon: const Icon(Icons.shuffle, color: AppColors.accent, size: 24),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: hasCams ? _toggleFavorite : null,
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? AppColors.accent : AppColors.cyber400,
              size: 24,
            ),
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Open in browser',
            onPressed: hasCams ? _openInBrowser : null,
            icon: const Icon(Icons.open_in_new, color: AppColors.cyber400, size: 22),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Fullscreen',
            onPressed: hasCams ? _openFullscreen : null,
            icon: const Icon(Icons.fullscreen, color: AppColors.cyber400, size: 22),
            visualDensity: VisualDensity.compact,
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert, color: AppColors.cyber400),
            color: AppColors.void900,
            onSelected: (value) {
              if (value == 'hide' && hasCams) {
                _skipAndHide();
              } else if (value == 'reload') {
                _loadCameras();
              } else if (value == 'filters') {
                _openFilters();
              } else if (value == 'settings') {
                _openSettings();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'hide',
                enabled: hasCams,
                child: const Text('Skip & hide', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Text('Reload data', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'filters',
                child: Text('Filters', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Content settings', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
