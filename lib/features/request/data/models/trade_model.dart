class Trade {
  final int id;
  final String name;
  final String description;
  final int standardRate;

  const Trade({
    required this.id,
    required this.name,
    required this.description,
    required this.standardRate,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      standardRate: json['standard_rate'] as int,
    );
  }
}
