/// Workout layout configuration model.
/// Represents the layout type a trainer has selected for a trainee.
class LayoutConfigModel {
  final String layoutType;
  final Map<String, dynamic> configOptions;

  const LayoutConfigModel({
    required this.layoutType,
    this.configOptions = const {},
  });

  factory LayoutConfigModel.fromJson(Map<String, dynamic> json) {
    return LayoutConfigModel(
      layoutType: json['layout_type'] as String? ?? 'classic',
      configOptions: json['config_options'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layout_type': layoutType,
      'config_options': configOptions,
    };
  }

  /// Default layout when no config exists or API fails.
  static const LayoutConfigModel defaultConfig = LayoutConfigModel(
    layoutType: 'classic',
  );

  bool get isClassic => layoutType == 'classic';
  bool get isCard => layoutType == 'card';
  bool get isMinimal => layoutType == 'minimal';
}
