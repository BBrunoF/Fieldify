class Trade {
  static const int platformFeePercent = 10;

  final int id;
  final String slug;
  final String displayName;
  final int standardRate;

  const Trade({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.standardRate,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      slug: json['slug'] as String,
      displayName: json['display_name'] as String,
      standardRate: (json['standard_rate'] as num).round(),
    );
  }
}
