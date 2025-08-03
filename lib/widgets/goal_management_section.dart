import 'package:flutter/material.dart';
import '../models/app_goal.dart';

class GoalManagementSection extends StatelessWidget {
  final List<AppGoal> goals;
  final Function(AppGoal) onGoalAdded;
  final Function(AppGoal) onGoalUpdated;
  final Function(String) onGoalDeleted;

  const GoalManagementSection({
    Key? key,
    required this.goals,
    required this.onGoalAdded,
    required this.onGoalUpdated,
    required this.onGoalDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.flag, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة الأهداف المخصصة لاستخدام التطبيقات',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أهداف مخصصة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على زر الإضافة لإنشاء هدف جديد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalTile(context, goal);
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showGoalDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة هدف جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTile(BuildContext context, AppGoal goal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            Icons.flag,
            color: Colors.blue[600],
          ),
        ),
        title: Text(
          goal.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.description.isNotEmpty)
              Text(
                goal.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            Text(
              'المدة: ${goal.durationMinutes} دقيقة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showGoalDialog(context, goal: goal);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, goal);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('تعديل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, {AppGoal? goal}) {
    final isEditing = goal != null;
    final nameController = TextEditingController(text: goal?.name ?? '');
    final descriptionController = TextEditingController(text: goal?.description ?? '');
    final durationController = TextEditingController(
      text: goal?.durationMinutes.toString() ?? '10',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل الهدف' : 'إضافة هدف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الهدف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                labelText: 'المدة (بالدقائق)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final description = descriptionController.text.trim();
              final duration = int.tryParse(durationController.text) ?? 10;

              if (name.isNotEmpty && duration > 0) {
                final newGoal = AppGoal(
                  id: goal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: description,
                  durationMinutes: duration,
                );

                if (isEditing) {
                  onGoalUpdated(newGoal);
                } else {
                  onGoalAdded(newGoal);
                }

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الهدف "${goal.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              onGoalDeleted(goal.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

