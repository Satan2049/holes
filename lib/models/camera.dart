enum StreamType { hls, mjpeg, youtube, embed, external, auto }

/// Content hint for filtering (you define values in JSON).
enum ContentCategory {
  traffic,
  outdoor,
  indoor,
  skyline,
  sample,
  other,
}

class Camera {
  const Camera({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.country,
    required this.city,
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.streamType = StreamType.auto,
    this.updateRateMs,
    this.category = ContentCategory.other,
    this.enabled = true,
    this.attribution,
    this.source,
    this.sourceUrl,
  });

  final String id;
  final String name;
  final String streamUrl;
  final String country;
  final String city;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final StreamType streamType;
  final int? updateRateMs;
  final ContentCategory category;
  final bool enabled;
  final String? attribution;
  final String? source;
  final String? sourceUrl;

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as String,
      name: json['name'] as String,
      streamUrl: json['streamUrl'] as String,
      country: json['country'] as String,
      city: json['city'] as String,
      latitude: _optionalDouble(json['latitude']),
      longitude: _optionalDouble(json['longitude']),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      streamType: _parseStreamType(json['streamType'] as String?),
      updateRateMs: json['updateRateMs'] as int?,
      category: _parseCategory(json['category'] as String?),
      enabled: json['enabled'] as bool? ?? true,
      attribution: json['attribution'] as String?,
      source: json['source'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
    );
  }

  String? get attributionLabel {
    if (attribution != null && attribution!.isNotEmpty) return attribution;
    if (source != null && source!.isNotEmpty) return source;
    return null;
  }

  static double? _optionalDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static StreamType _parseStreamType(String? value) {
    switch (value) {
      case 'hls':
        return StreamType.hls;
      case 'mjpeg':
        return StreamType.mjpeg;
      case 'youtube':
        return StreamType.youtube;
      case 'embed':
      case 'external':
        return StreamType.embed;
      default:
        return StreamType.auto;
    }
  }

  static ContentCategory _parseCategory(String? value) {
    switch (value?.toLowerCase()) {
      case 'traffic':
        return ContentCategory.traffic;
      case 'outdoor':
        return ContentCategory.outdoor;
      case 'indoor':
        return ContentCategory.indoor;
      case 'skyline':
        return ContentCategory.skyline;
      case 'sample':
        return ContentCategory.sample;
      default:
        return ContentCategory.other;
    }
  }

  String get locationLabel => city.isEmpty ? country : '$city, $country';
}

class CameraIndex {
  const CameraIndex({required this.version, required this.cameras});

  final int version;
  final List<Camera> cameras;

  factory CameraIndex.fromJson(Map<String, dynamic> json) {
    return CameraIndex(
      version: json['version'] as int? ?? 1,
      cameras: (json['cameras'] as List<dynamic>)
          .map((e) => Camera.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
