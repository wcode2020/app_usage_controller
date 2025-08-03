import 'package:flutter/material.dart';
import '../models/monitored_app.dart';
import '../models/app_goal.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/goal_management_section.dart';
import '../services/app_controller_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppControllerService _controllerService = AppControllerService();
  final StorageService _storageService = StorageService();
  
  List<MonitoredApp> monitoredApps = [];
  List<AppGoal> customGoals = [];
  bool isNotificationsEnabled = true;
  bool isOverlayEnabled = true;
  bool isMonitoringEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _controllerService.initialize();
      await _loadSettings();
      
      // Start monitoring if enabled
      if (isMonitoringEnabled) {
        await _controllerService.startMonitoring();
      }
    } catch (e) {
      print('Error initializing app: $e');
      _showErrorDialog('خطأ في تهيئة التطبيق: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      monitoredApps = _controllerService.monitoredApps;
      customGoals = _controllerService.availableGoals;
      
      isNotificationsEnabled = await _storageService.isNotificationsEnabled();
      isOverlayEnabled = await _storageService.isOverlayEnabled();
      isMonitoringEnabled = await _storageService.isMonitoringEnabled();
      
      // Add sample apps if none exist
      if (monitoredApps.isEmpty) {
        monitoredApps = _getSampleApps();
        await _controllerService.updateMonitoredApps(monitoredApps);
      }
      
      setState(() {});
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  List<MonitoredApp> _getSampleApps() {
    return [
      MonitoredApp(
        packageName: 'com.facebook.katana',
        appName: 'Facebook',
        isEnabled: true,
      ),
      MonitoredApp(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        isEnabled: true,
      ),
      MonitoredApp(
        packageName: 'com.twitter.android',
        appName: 'Twitter',
        isEnabled: false,
      ),
      MonitoredApp(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        isEnabled: true,
      ),
      MonitoredApp(
        packageName: 'com.snapchat.android',
        appName: 'Snapchat',
        isEnabled: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue[600]),
              const SizedBox(height: 16),
              const Text('جاري تهيئة التطبيق...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات تقنين الاستخدام'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isMonitoringEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleMonitoring,
            tooltip: isMonitoringEnabled ? 'إيقاف المراقبة' : 'بدء المراقبة',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'التطبيقات', icon: Icon(Icons.apps)),
            Tab(text: 'الأهداف', icon: Icon(Icons.flag)),
            Tab(text: 'عام', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppsTab(),
          _buildGoalsTab(),
          _buildGeneralTab(),
        ],
      ),
    );
  }

  Widget _buildAppsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'اختر التطبيقات التي تريد تقنين استخدامها',
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
          child: ListView.builder(
            itemCount: monitoredApps.length,
            itemBuilder: (context, index) {
              final app = monitoredApps[index];
              return AppListTile(
                app: app,
                onToggle: (isEnabled) async {
                  setState(() {
                    monitoredApps[index] = app.copyWith(isEnabled: isEnabled);
                  });
                  await _controllerService.updateMonitoredApps(monitoredApps);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addNewApp,
            icon: const Icon(Icons.add),
            label: const Text('إضافة تطبيق جديد'),
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

  Widget _buildGoalsTab() {
    return GoalManagementSection(
      goals: customGoals,
      onGoalAdded: (goal) async {
        await _controllerService.addCustomGoal(goal);
        setState(() {
          customGoals = _controllerService.availableGoals;
        });
      },
      onGoalUpdated: (goal) async {
        await _controllerService.updateCustomGoals(
          customGoals.map((g) => g.id == goal.id ? goal : g).toList(),
        );
        setState(() {
          customGoals = _controllerService.availableGoals;
        });
      },
      onGoalDeleted: (goalId) async {
        await _controllerService.removeCustomGoal(goalId);
        setState(() {
          customGoals = _controllerService.availableGoals;
        });
      },
    );
  }

  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('تفعيل المراقبة'),
                subtitle: const Text('مراقبة استخدام التطبيقات المحددة'),
                value: isMonitoringEnabled,
                onChanged: (value) async {
                  await _storageService.setMonitoringEnabled(value);
                  setState(() {
                    isMonitoringEnabled = value;
                  });
                  if (value) {
                    await _controllerService.startMonitoring();
                  } else {
                    await _controllerService.stopMonitoring();
                  }
                },
                activeColor: Colors.blue[600],
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('تفعيل الإشعارات'),
                subtitle: const Text('إرسال تنبيهات عند انتهاء الوقت المحدد'),
                value: isNotificationsEnabled,
                onChanged: (value) async {
                  await _storageService.setNotificationsEnabled(value);
                  setState(() {
                    isNotificationsEnabled = value;
                  });
                },
                activeColor: Colors.blue[600],
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('تفعيل النافذة المنبثقة'),
                subtitle: const Text('عرض نافذة اختيار الهدف عند فتح التطبيقات'),
                value: isOverlayEnabled,
                onChanged: (value) async {
                  await _storageService.setOverlayEnabled(value);
                  setState(() {
                    isOverlayEnabled = value;
                  });
                },
                activeColor: Colors.blue[600],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.history, color: Colors.blue[600]),
                title: const Text('سجل الاستخدام'),
                subtitle: const Text('عرض تاريخ استخدام التطبيقات'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showUsageHistory();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.bar_chart, color: Colors.blue[600]),
                title: const Text('الإحصائيات'),
                subtitle: const Text('عرض إحصائيات مفصلة عن الاستخدام'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showStatistics();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.download, color: Colors.blue[600]),
                title: const Text('تصدير البيانات'),
                subtitle: const Text('تصدير الإعدادات وسجل الاستخدام'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _exportData,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.upload, color: Colors.blue[600]),
                title: const Text('استيراد البيانات'),
                subtitle: const Text('استيراد الإعدادات من ملف'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _importData,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red[600]),
                title: const Text('مسح جميع البيانات'),
                subtitle: const Text('حذف جميع الإعدادات وسجل الاستخدام'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _clearAllData,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.help_outline, color: Colors.blue[600]),
                title: const Text('المساعدة'),
                subtitle: const Text('كيفية استخدام التطبيق'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showHelp,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blue[600]),
                title: const Text('حول التطبيق'),
                subtitle: const Text('معلومات عن التطبيق والمطور'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showAbout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleMonitoring() async {
    final newValue = !isMonitoringEnabled;
    await _storageService.setMonitoringEnabled(newValue);
    setState(() {
      isMonitoringEnabled = newValue;
    });
    
    if (newValue) {
      await _controllerService.startMonitoring();
      _showSnackBar('تم بدء المراقبة');
    } else {
      await _controllerService.stopMonitoring();
      _showSnackBar('تم إيقاف المراقبة');
    }
  }

  void _addNewApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تطبيق جديد'),
        content: const Text('هذه الميزة ستكون متاحة قريباً.\n\nيمكنك حالياً تعديل التطبيقات الموجودة في القائمة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showUsageHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سجل الاستخدام'),
        content: const Text('ميزة سجل الاستخدام ستكون متاحة قريباً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإحصائيات'),
        content: const Text('ميزة الإحصائيات ستكون متاحة قريباً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: const Text('ميزة تصدير البيانات ستكون متاحة قريباً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _importData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد البيانات'),
        content: const Text('ميزة استيراد البيانات ستكون متاحة قريباً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد المسح'),
        content: const Text('هل أنت متأكد من حذف جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _storageService.clearAllData();
              Navigator.pop(context);
              _showSnackBar('تم مسح جميع البيانات');
              await _loadSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const SingleChildScrollView(
          child: Text(
            'كيفية استخدام التطبيق:\n\n'
            '1. اختر التطبيقات التي تريد تقنين استخدامها من تبويب "التطبيقات"\n\n'
            '2. أضف أهدافك المخصصة من تبويب "الأهداف"\n\n'
            '3. فعّل المراقبة من تبويب "عام"\n\n'
            '4. عند فتح أي تطبيق مراقب، ستظهر نافذة لاختيار الهدف والمدة\n\n'
            '5. ستتلقى تنبيهات عند انتهاء الوقت المحدد\n\n'
            'ملاحظة: يتطلب التطبيق صلاحيات خاصة للعمل بشكل صحيح.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حول التطبيق'),
        content: const Text(
          'تطبيق تقنين استخدام التطبيقات\n\n'
          'الإصدار: 1.0.0\n\n'
          'يساعدك هذا التطبيق على تقنين استخدام التطبيقات الاجتماعية والتحكم في الوقت المقضي عليها.\n\n'
          'تم تطويره باستخدام Flutter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
}

