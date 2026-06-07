import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../services/content_filter_service.dart';
import '../theme/app_theme.dart';
import '../utils/platform_playback.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.filters,
    required this.countries,
    this.favoriteCount = 0,
  });

  final BrowseFilters filters;
  final List<String> countries;
  final int favoriteCount;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _country;
  late ContentCategory? _category;
  late StreamType? _streamType;
  late bool _webFriendlyOnly;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _country = widget.filters.country;
    _category = widget.filters.category;
    _streamType = widget.filters.streamTypeOnly;
    _webFriendlyOnly = widget.filters.webFriendlyOnly;
    _favoritesOnly = widget.filters.favoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Favorites only', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              widget.favoriteCount == 0
                  ? 'Star cameras from the controls bar'
                  : '${widget.favoriteCount} saved',
              style: const TextStyle(color: AppColors.cyber400, fontSize: 11),
            ),
            value: _favoritesOnly,
            activeThumbColor: AppColors.accent,
            onChanged: widget.favoriteCount == 0 && !_favoritesOnly
                ? null
                : (v) => setState(() => _favoritesOnly = v),
          ),
          DropdownButtonFormField<String?>(
            initialValue: _country,
            dropdownColor: AppColors.void900,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Country'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any country')),
              ...widget.countries.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
            ],
            onChanged: (v) => setState(() => _country = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ContentCategory?>(
            initialValue: _category,
            dropdownColor: AppColors.void900,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any category')),
              ...ContentCategory.values
                  .where((c) => c != ContentCategory.sample)
                  .map(
                (c) => DropdownMenuItem(value: c, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<StreamType?>(
            initialValue: _streamType,
            dropdownColor: AppColors.void900,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Stream type'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any')),
              DropdownMenuItem(value: StreamType.hls, child: Text('HLS')),
              DropdownMenuItem(value: StreamType.mjpeg, child: Text('MJPEG')),
            ],
            onChanged: (v) => setState(() => _streamType = v),
          ),
          if (PlatformPlayback.isWeb) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Web-friendly only', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'HTTPS image feeds (skips HLS)',
                style: TextStyle(color: AppColors.cyber400, fontSize: 11),
              ),
              value: _webFriendlyOnly,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => setState(() => _webFriendlyOnly = v),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    BrowseFilters(
                      query: widget.filters.query,
                      webFriendlyOnly: PlatformPlayback.isWeb,
                    ),
                  );
                },
                child: const Text('Clear'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    BrowseFilters(
                      query: widget.filters.query,
                      country: _country,
                      category: _category,
                      streamTypeOnly: _streamType,
                      webFriendlyOnly: _webFriendlyOnly,
                      favoritesOnly: _favoritesOnly,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
