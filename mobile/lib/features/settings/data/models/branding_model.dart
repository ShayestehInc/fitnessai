import 'dart:ui';

/// Represents a trainer's white-label branding configuration.
class BrandingModel {
  final String appName;
  final String primaryColor;
  final String secondaryColor;
  final String? logoUrl;
  final String? createdAt;
  final String? updatedAt;

  const BrandingModel({
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Default branding (FitnessAI indigo theme).
  static const defaultBranding = BrandingModel(
    appName: '',
    primaryColor: '#6366F1',
    secondaryColor: '#818CF8',
  );

  /// Whether this branding differs from the default.
  bool get isCustomized =>
      appName.isNotEmpty ||
      primaryColor != '#6366F1' ||
      secondaryColor != '#818CF8' ||
      logoUrl != null;

  /// Parse primary color as a Flutter Color.
  Color get primaryColorValue => _hexToColor(primaryColor);

  /// Parse secondary color as a Flutter Color.
  Color get secondaryColorValue => _hexToColor(secondaryColor);

  /// Display name: trainer's app_name or default "FitnessAI".
  String get displayName => appName.isNotEmpty ? appName : 'FitnessAI';

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      appName: (json['app_name'] as String?) ?? '',
      primaryColor: (json['primary_color'] as String?) ?? '#6366F1',
      secondaryColor: (json['secondary_color'] as String?) ?? '#818CF8',
      logoUrl: json['logo_url'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
    };
  }

  /// Convert to JSON for SharedPreferences caching.
  Map<String, dynamic> toCacheJson() {
    return {
      'app_name': appName,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'logo_url': logoUrl,
    };
  }

  factory BrandingModel.fromCacheJson(Map<String, dynamic> json) {
    return BrandingModel(
      appName: (json['app_name'] as String?) ?? '',
      primaryColor: (json['primary_color'] as String?) ?? '#6366F1',
      secondaryColor: (json['secondary_color'] as String?) ?? '#818CF8',
      logoUrl: json['logo_url'] as String?,
    );
  }

  BrandingModel copyWith({
    String? appName,
    String? primaryColor,
    String? secondaryColor,
    String? logoUrl,
  }) {
    return BrandingModel(
      appName: appName ?? this.appName,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return const Color(0xFF6366F1);
    final intValue = int.tryParse(cleaned, radix: 16);
    if (intValue == null) return const Color(0xFF6366F1);
    return Color(0xFF000000 | intValue);
  }

  /// Convert a Color to hex string.
  static String colorToHex(Color color) {
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
