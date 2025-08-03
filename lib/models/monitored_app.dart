class MonitoredApp {
  final String packageName;
  final String appName;
  final String? iconPath;
  final bool isEnabled;

  MonitoredApp({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
      'isEnabled': isEnabled,
    };
  }

  factory MonitoredApp.fromJson(Map<String, dynamic> json) {
    return MonitoredApp(
      packageName: json['packageName'],
      appName: json['appName'],
      iconPath: json['iconPath'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  MonitoredApp copyWith({
    String? packageName,
    String? appName,
    String? iconPath,
    bool? isEnabled,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitoredApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

