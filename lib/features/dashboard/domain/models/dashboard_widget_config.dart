class DashboardWidgetConfig {
  final String id;
  final int widthSpan;
  final int heightSpan;

  const DashboardWidgetConfig({
    required this.id,
    this.widthSpan = 1,
    this.heightSpan = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'widthSpan': widthSpan,
      'heightSpan': heightSpan,
    };
  }

  factory DashboardWidgetConfig.fromMap(Map<String, dynamic> map) {
    return DashboardWidgetConfig(
      id: map['id'] as String,
      widthSpan: map['widthSpan'] as int? ?? 1,
      heightSpan: map['heightSpan'] as int? ?? 1,
    );
  }

  DashboardWidgetConfig copyWith({
    String? id,
    int? widthSpan,
    int? heightSpan,
  }) {
    return DashboardWidgetConfig(
      id: id ?? this.id,
      widthSpan: widthSpan ?? this.widthSpan,
      heightSpan: heightSpan ?? this.heightSpan,
    );
  }

  @override
  String toString() => 'DashboardWidgetConfig(id: $id, widthSpan: $widthSpan, heightSpan: $heightSpan)';
}
