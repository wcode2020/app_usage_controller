class UsageSession {
  final String id;
  final String packageName;
  final String appName;
  final String goalId;
  final String goalName;
  final int plannedDurationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final bool wasCompleted;

  UsageSession({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.goalId,
    required this.goalName,
    required this.plannedDurationMinutes,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.wasCompleted = false,
  });

  int get actualDurationMinutes {
    if (endTime != null) {
      return endTime!.difference(startTime).inMinutes;
    } else if (isActive) {
      return DateTime.now().difference(startTime).inMinutes;
    }
    return 0;
  }

  int get remainingMinutes {
    final elapsed = actualDurationMinutes;
    return plannedDurationMinutes - elapsed;
  }

  bool get isOvertime => remainingMinutes < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'goalId': goalId,
      'goalName': goalName,
      'plannedDurationMinutes': plannedDurationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
      'wasCompleted': wasCompleted,
    };
  }

  factory UsageSession.fromJson(Map<String, dynamic> json) {
    return UsageSession(
      id: json['id'],
      packageName: json['packageName'],
      appName: json['appName'],
      goalId: json['goalId'],
      goalName: json['goalName'],
      plannedDurationMinutes: json['plannedDurationMinutes'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isActive: json['isActive'] ?? false,
      wasCompleted: json['wasCompleted'] ?? false,
    );
  }

  UsageSession copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? goalId,
    String? goalName,
    int? plannedDurationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    bool? wasCompleted,
  }) {
    return UsageSession(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      wasCompleted: wasCompleted ?? this.wasCompleted,
    );
  }
}

