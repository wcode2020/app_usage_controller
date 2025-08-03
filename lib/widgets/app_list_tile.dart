import 'package:flutter/material.dart';
import '../models/monitored_app.dart';

class AppListTile extends StatelessWidget {
  final MonitoredApp app;
  final Function(bool) onToggle;

  const AppListTile({
    Key? key,
    required this.app,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            Icons.android,
            color: Colors.blue[600],
          ),
        ),
        title: Text(
          app.appName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          app.packageName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: app.isEnabled,
          onChanged: onToggle,
          activeColor: Colors.blue[600],
        ),
      ),
    );
  }
}

