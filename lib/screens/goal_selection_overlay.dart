import 'package:flutter/material.dart';
import '../models/app_goal.dart';
import '../models/monitored_app.dart';

class GoalSelectionOverlay extends StatefulWidget {
  final MonitoredApp app;
  final List<AppGoal> availableGoals;
  final Function(AppGoal goal, int customDuration) onGoalSelected;
  final VoidCallback onCancel;

  const GoalSelectionOverlay({
    Key? key,
    required this.app,
    required this.availableGoals,
    required this.onGoalSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<GoalSelectionOverlay> createState() => _GoalSelectionOverlayState();
}

class _GoalSelectionOverlayState extends State<GoalSelectionOverlay> {
  AppGoal? selectedGoal;
  int customDuration = 10;
  final TextEditingController customDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    customDurationController.text = customDuration.toString();
  }

  @override
  void dispose() {
    customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.apps,
                    size: 32,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحديد هدف الاستخدام',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          widget.app.appName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goals List
              Text(
                'ما هو هدفك من استخدام هذا التطبيق؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              ...widget.availableGoals.map((goal) => _buildGoalOption(goal)),

              const SizedBox(height: 20),

              // Custom Duration
              Text(
                'المدة المطلوبة (بالدقائق):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Quick duration buttons
                  _buildDurationButton(5),
                  const SizedBox(width: 8),
                  _buildDurationButton(10),
                  const SizedBox(width: 8),
                  _buildDurationButton(15),
                  const SizedBox(width: 8),
                  _buildDurationButton(30),
                  const SizedBox(width: 16),

                  // Custom input
                  Expanded(
                    child: TextField(
                      controller: customDurationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'مخصص',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        final duration = int.tryParse(value);
                        if (duration != null && duration > 0) {
                          setState(() {
                            customDuration = duration;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedGoal != null
                          ? () => widget.onGoalSelected(selectedGoal!, customDuration)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('بدء الاستخدام'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(AppGoal goal) {
    final isSelected = selectedGoal?.id == goal.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedGoal = goal;
            customDuration = goal.durationMinutes;
            customDurationController.text = goal.durationMinutes.toString();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.blue[50] : Colors.transparent,
          ),
          child: Row(
            children: [
              Radio<AppGoal>(
                value: goal,
                groupValue: selectedGoal,
                onChanged: (value) {
                  setState(() {
                    selectedGoal = value;
                    customDuration = goal.durationMinutes;
                    customDurationController.text = goal.durationMinutes.toString();
                  });
                },
                activeColor: Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.blue[700] : Colors.grey[800],
                      ),
                    ),
                    if (goal.description.isNotEmpty)
                      Text(
                        goal.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.blue[600] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${goal.durationMinutes} دقيقة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationButton(int minutes) {
    final isSelected = customDuration == minutes;
    return InkWell(
      onTap: () {
        setState(() {
          customDuration = minutes;
          customDurationController.text = minutes.toString();
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$minutes د',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

