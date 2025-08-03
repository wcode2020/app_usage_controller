# تعليمات البناء والنشر

## متطلبات النظام

### Flutter SDK
- Flutter 3.24.5 أو أحدث
- Dart 3.5.4 أو أحدث

### Android Development
- Android Studio أو VS Code مع إضافات Flutter
- Android SDK (API level 21 أو أحدث)
- Java Development Kit (JDK) 17 أو أحدث

### أدوات إضافية
- Git
- Command Line Tools

## إعداد بيئة التطوير

### 1. تثبيت Flutter
```bash
# تحميل Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz

# استخراج الملفات
tar xf flutter_linux_3.24.5-stable.tar.xz

# إضافة Flutter إلى PATH
export PATH="$PATH:`pwd`/flutter/bin"
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.bashrc
```

### 2. التحقق من التثبيت
```bash
flutter doctor
```

### 3. إعداد Android
```bash
# تثبيت Android Studio أو Android SDK
# قبول تراخيص Android
flutter doctor --android-licenses
```

## استنساخ وإعداد المشروع

### 1. استنساخ المشروع
```bash
git clone <repository-url>
cd app_usage_controller
```

### 2. تثبيت التبعيات
```bash
flutter pub get
```

### 3. التحقق من عدم وجود أخطاء
```bash
flutter analyze
```

## البناء للتطوير

### 1. تشغيل التطبيق في وضع التطوير
```bash
# تشغيل على جهاز متصل أو محاكي
flutter run

# تشغيل مع Hot Reload
flutter run --hot
```

### 2. بناء APK للتطوير
```bash
flutter build apk --debug
```

الملف المُنتج: `build/app/outputs/flutter-apk/app-debug.apk`

## البناء للإنتاج

### 1. تنظيف المشروع
```bash
flutter clean
flutter pub get
```

### 2. بناء APK للإنتاج
```bash
flutter build apk --release
```

الملف المُنتج: `build/app/outputs/flutter-apk/app-release.apk`

### 3. بناء App Bundle (للنشر على Google Play)
```bash
flutter build appbundle --release
```

الملف المُنتج: `build/app/outputs/bundle/release/app-release.aab`

### 4. بناء APK مقسم حسب البنية
```bash
flutter build apk --split-per-abi --release
```

الملفات المُنتجة:
- `app-arm64-v8a-release.apk`
- `app-armeabi-v7a-release.apk`
- `app-x86_64-release.apk`

## التوقيع الرقمي (للنشر)

### 1. إنشاء مفتاح التوقيع
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. إعداد ملف key.properties
إنشاء ملف `android/key.properties`:
```properties
storePassword=<password from previous step>
keyPassword=<password from previous step>
keyAlias=upload
storeFile=<location of the key store file, such as /Users/<user name>/upload-keystore.jks>
```

### 3. تحديث build.gradle
في ملف `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4. بناء APK موقع
```bash
flutter build apk --release
```

## اختبار التطبيق

### 1. اختبار الوحدة
```bash
flutter test
```

### 2. اختبار التكامل
```bash
flutter drive --target=test_driver/app.dart
```

### 3. اختبار على أجهزة متعددة
- اختبار على أجهزة Android مختلفة
- اختبار إصدارات Android مختلفة (API 21+)
- اختبار أحجام شاشات مختلفة

## التحقق من الجودة

### 1. تحليل الكود
```bash
flutter analyze
```

### 2. فحص الأداء
```bash
flutter build apk --release --analyze-size
```

### 3. فحص التبعيات
```bash
flutter pub deps
flutter pub outdated
```

## النشر

### 1. Google Play Store
1. إنشاء حساب مطور على Google Play Console
2. رفع App Bundle (.aab)
3. ملء معلومات التطبيق
4. إعداد الوصف والصور
5. نشر التطبيق

### 2. التوزيع المباشر
1. رفع APK على خدمة استضافة
2. توفير رابط التحميل
3. إرشاد المستخدمين لتفعيل "مصادر غير معروفة"

## استكشاف الأخطاء

### مشاكل شائعة وحلولها

#### 1. خطأ في التبعيات
```bash
flutter clean
flutter pub get
```

#### 2. مشاكل Android SDK
```bash
flutter doctor
flutter doctor --android-licenses
```

#### 3. مشاكل الصلاحيات
- التأكد من إضافة جميع الصلاحيات في AndroidManifest.xml
- اختبار طلب الصلاحيات في التطبيق

#### 4. مشاكل البناء
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

#### 5. مشاكل الأداء
- استخدام `flutter build apk --release` بدلاً من debug
- تحسين الصور والموارد
- تقليل حجم التطبيق

## تحسين الأداء

### 1. تقليل حجم APK
```bash
# استخدام ProGuard
flutter build apk --release --obfuscate --split-debug-info=/<project-name>/<directory>

# تقسيم APK حسب البنية
flutter build apk --split-per-abi --release
```

### 2. تحسين الصور
- استخدام تنسيقات مضغوطة (WebP)
- تحسين أحجام الصور
- استخدام Vector Graphics عند الإمكان

### 3. تحسين الكود
- إزالة الكود غير المستخدم
- تحسين الاستيراد
- استخدام const constructors

## المراقبة والتحليل

### 1. إضافة Firebase Analytics
```yaml
dependencies:
  firebase_analytics: ^10.7.4
```

### 2. إضافة Crashlytics
```yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

### 3. مراقبة الأداء
```yaml
dependencies:
  firebase_performance: ^0.9.3+16
```

## النسخ الاحتياطي والاستعادة

### 1. نسخ احتياطي للكود
```bash
git add .
git commit -m "Release version X.X.X"
git tag vX.X.X
git push origin main --tags
```

### 2. نسخ احتياطي للمفاتيح
- حفظ مفتاح التوقيع في مكان آمن
- توثيق كلمات المرور
- إنشاء نسخ احتياطية متعددة

## قائمة التحقق قبل النشر

- [ ] اختبار التطبيق على أجهزة متعددة
- [ ] التحقق من جميع الصلاحيات
- [ ] اختبار جميع الميزات
- [ ] تحديث رقم الإصدار
- [ ] إنشاء ملاحظات الإصدار
- [ ] بناء APK موقع
- [ ] اختبار APK النهائي
- [ ] تحضير مواد التسويق (صور، وصف)
- [ ] رفع التطبيق للمتجر

---

اتباع هذه التعليمات سيضمن بناء ونشر التطبيق بنجاح.

