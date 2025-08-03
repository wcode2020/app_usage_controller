class AppGoal {
  final String id;
  final String name;
  final int durationMinutes;
  final String description;

  AppGoal({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'description': description,
    };
  }

  factory AppGoal.fromJson(Map<String, dynamic> json) {
    return AppGoal(
      id: json['id'],
      name: json['name'],
      durationMinutes: json['durationMinutes'],
      description: json['description'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppGoal && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

