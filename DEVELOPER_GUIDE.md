# دليل المطور - تطبيق تقنين استخدام التطبيقات

## نظرة عامة على البنية التقنية

هذا التطبيق مبني باستخدام Flutter ويستخدم نمط الخدمات (Services Pattern) لفصل منطق العمل عن واجهة المستخدم.

## البنية العامة

### 1. النماذج (Models)
تحتوي على تعريفات البيانات الأساسية:

#### AppGoal
```dart
class AppGoal {
  final String id;
  final String name;
  final int durationMinutes;
  final String description;
}
```

#### MonitoredApp
```dart
class MonitoredApp {
  final String packageName;
  final String appName;
  final String? iconPath;
  final bool isEnabled;
}
```

#### UsageSession
```dart
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
}
```

### 2. الخدمات (Services)

#### AppControllerService
الخدمة الرئيسية التي تنسق بين جميع الخدمات الأخرى:
- إدارة دورة حياة التطبيق
- تنسيق عمليات المراقبة
- إدارة الجلسات النشطة
- ربط الأحداث بالإجراءات

#### AppUsageService
مسؤولة عن مراقبة استخدام التطبيقات:
- اكتشاف فتح التطبيقات المراقبة
- تتبع الوقت المستخدم
- إرسال أحداث عند فتح التطبيقات

#### NotificationService
إدارة الإشعارات المحلية:
- إشعارات انتهاء الوقت
- تحذيرات قبل انتهاء الوقت
- إشعارات تجاوز الوقت المحدد

#### OverlayService
إدارة النوافذ المنبثقة:
- عرض نافذة اختيار الهدف
- عرض مؤقت الوقت المتبقي
- عرض تحذيرات الوقت

#### StorageService
تخزين البيانات محلياً:
- حفظ وتحميل الإعدادات
- إدارة الأهداف المخصصة
- تخزين سجل الاستخدام

### 3. الشاشات (Screens)

#### SettingsScreen
الشاشة الرئيسية للتطبيق تحتوي على:
- تبويب التطبيقات المراقبة
- تبويب إدارة الأهداف
- تبويب الإعدادات العامة

#### GoalSelectionOverlay
النافذة المنبثقة لاختيار الهدف والمدة

### 4. الويدجت (Widgets)

#### AppListTile
عرض التطبيق في قائمة التطبيقات المراقبة

#### GoalManagementSection
إدارة الأهداف المخصصة (إضافة، تعديل، حذف)

## تدفق العمل

### 1. تهيئة التطبيق
```
AppControllerService.initialize()
├── NotificationService.initialize()
├── StorageService.initialize()
├── تحميل الإعدادات المحفوظة
└── طلب الصلاحيات المطلوبة
```

### 2. بدء المراقبة
```
AppControllerService.startMonitoring()
├── AppUsageService.startMonitoring()
├── الاستماع لأحداث فتح التطبيقات
└── معالجة الأحداث
```

### 3. معالجة فتح التطبيق
```
عند فتح تطبيق مراقب:
├── التحقق من وجود جلسة نشطة
├── عرض نافذة اختيار الهدف
├── بدء جلسة جديدة
├── تشغيل مؤقت المراقبة
└── حفظ بيانات الجلسة
```

### 4. مراقبة الوقت
```
كل دقيقة:
├── التحقق من الوقت المتبقي
├── إرسال تحذيرات (5 دقائق، 1 دقيقة)
├── إرسال إشعار انتهاء الوقت
└── تسجيل تجاوز الوقت
```

## الصلاحيات المطلوبة

### Android Permissions
```xml
<!-- عرض النوافذ فوق التطبيقات الأخرى -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

<!-- مراقبة استخدام التطبيقات -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />

<!-- الإشعارات -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- منع النوم -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- بدء التشغيل مع النظام -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- الاهتزاز -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- الإشعارات ملء الشاشة -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

## التحديات التقنية والحلول

### 1. مراقبة التطبيقات
**التحدي**: صلاحية `PACKAGE_USAGE_STATS` تتطلب موافقة يدوية من المستخدم
**الحل**: توجيه المستخدم لإعدادات النظام لمنح الصلاحية

### 2. النوافذ المنبثقة
**التحدي**: قيود Android على النوافذ المنبثقة
**الحل**: استخدام `flutter_overlay_window` مع طلب صلاحية `SYSTEM_ALERT_WINDOW`

### 3. مراقبة التطبيقات في الخلفية
**التحدي**: قيود توفير البطارية
**الحل**: استخدام مراقبة دورية كل 5 ثوانٍ بدلاً من المراقبة المستمرة

### 4. إغلاق التطبيقات
**التحدي**: Android لا يسمح بإغلاق التطبيقات الأخرى
**الحل**: التركيز على الإشعارات القوية والتنبيهات

## أفضل الممارسات

### 1. إدارة الذاكرة
- استخدام Singleton pattern للخدمات
- تنظيف الموارد في dispose()
- تجنب تسريب الذاكرة في StreamSubscriptions

### 2. إدارة الحالة
- استخدام setState() للتحديثات البسيطة
- فصل منطق العمل عن واجهة المستخدم
- استخدام الخدمات لإدارة البيانات المشتركة

### 3. معالجة الأخطاء
- استخدام try-catch في العمليات الحساسة
- تسجيل الأخطاء للتشخيص
- توفير رسائل خطأ واضحة للمستخدم

### 4. الأداء
- تجنب العمليات الثقيلة في UI thread
- استخدام async/await للعمليات غير المتزامنة
- تحسين استهلاك البطارية

## اختبار التطبيق

### 1. اختبار الوحدة
```bash
flutter test
```

### 2. اختبار التكامل
- اختبار تدفق العمل الكامل
- اختبار الصلاحيات
- اختبار الإشعارات

### 3. اختبار الأداء
- مراقبة استهلاك البطارية
- قياس استهلاك الذاكرة
- اختبار الاستقرار

## البناء والنشر

### 1. بناء APK للتطوير
```bash
flutter build apk --debug
```

### 2. بناء APK للإنتاج
```bash
flutter build apk --release
```

### 3. بناء App Bundle
```bash
flutter build appbundle --release
```

## التطوير المستقبلي

### ميزات مقترحة
1. **دعم iOS**: تطوير نسخة للآيفون
2. **تحليلات متقدمة**: رسوم بيانية وإحصائيات مفصلة
3. **الذكاء الاصطناعي**: اقتراحات ذكية للأهداف والمدد
4. **المزامنة السحابية**: مزامنة البيانات عبر الأجهزة
5. **التكامل**: ربط مع تطبيقات الإنتاجية الأخرى

### تحسينات تقنية
1. **الأداء**: تحسين خوارزميات المراقبة
2. **واجهة المستخدم**: تحسين التصميم والتفاعل
3. **الاختبارات**: إضافة اختبارات شاملة
4. **التوثيق**: توسيع التوثيق والأمثلة

## المساهمة في التطوير

### إعداد بيئة التطوير
1. تثبيت Flutter SDK
2. إعداد Android Studio/VS Code
3. استنساخ المشروع
4. تشغيل `flutter pub get`

### إرشادات المساهمة
1. اتباع نمط الكود الموجود
2. إضافة اختبارات للميزات الجديدة
3. تحديث التوثيق
4. اختبار التغييرات على أجهزة متعددة

### هيكل الكود
- استخدام أسماء واضحة للمتغيرات والدوال
- إضافة تعليقات للكود المعقد
- اتباع مبادئ SOLID
- فصل الاهتمامات (Separation of Concerns)

---

هذا الدليل يوفر نظرة شاملة على البنية التقنية للتطبيق ويساعد المطورين على فهم وتطوير التطبيق بفعالية.

