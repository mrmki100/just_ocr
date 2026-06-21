import 'package:flutter/material.dart';
import 'app_language.dart';

/// Localization strings for the justOCR app
/// Supports: Persian (fa), Dutch (nl), Arabic (ar), English (en)
class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // General
  String get appName => _getString('appName');
  String get welcome => _getString('welcome');
  String get loading => _getString('loading');
  String get error => _getString('error');
  String get retry => _getString('retry');
  String get cancel => _getString('cancel');
  String get confirm => _getString('confirm');
  String get done => _getString('done');
  String get settings => _getString('settings');
  String get close => _getString('close');

  // Language Selection
  String get selectLanguage => _getString('selectLanguage');
  String get chooseLanguage => _getString('chooseLanguage');
  String get languageDescription => _getString('languageDescription');
  String get continueText => _getString('continueText');

  // Authentication
  String get loginTitle => _getString('loginTitle');
  String get loginSubtitle => _getString('loginSubtitle');
  String get loginWithGoogle => _getString('loginWithGoogle');
  String get apiKeySetupTitle => _getString('apiKeySetupTitle');
  String get apiKeyInstructions => _getString('apiKeyInstructions');
  String get step1 => _getString('step1');
  String get step2 => _getString('step2');
  String get step3 => _getString('step3');
  String get step4 => _getString('step4');
  String get step5 => _getString('step5');
  String get openLink => _getString('openLink');
  String get iCopiedKey => _getString('iCopiedKey');
  String get pasteApiKey => _getString('pasteApiKey');
  String get apiKeyHint => _getString('apiKeyHint');
  String get saveApiKey => _getString('saveApiKey');
  String get accountSection => _getString('accountSection');
  String get signedInAs => _getString('signedInAs');
  String get notSignedIn => _getString('notSignedIn');
  String get setupApiKey => _getString('setupApiKey');
  String get signOut => _getString('signOut');
  String get apiKeySaved => _getString('apiKeySaved');
  String get loginRequired => _getString('loginRequired');
  String get apiKey => _getString('apiKey');
  String get configured => _getString('configured');
  String get notConfigured => _getString('notConfigured');

  // Navigation Tabs
  String get booksTab => _getString('booksTab');
  String get scanTab => _getString('scanTab');
  String get profileTab => _getString('profileTab');

  // Books Tab
  String get myBooks => _getString('myBooks');
  String get noBooks => _getString('noBooks');
  String get addBook => _getString('addBook');
  String get searchBooks => _getString('searchBooks');
  String get bookTitle => _getString('bookTitle');
  String get lastRead => _getString('lastRead');
  String get readingProgress => _getString('readingProgress');

  // Scan Tab
  String get scanDocument => _getString('scanDocument');
  String get takePhoto => _getString('takePhoto');
  String get chooseFromGallery => _getString('chooseFromGallery');
  String get importFile => _getString('importFile');
  String get scanning => _getString('scanning');
  String get processing => _getString('processing');
  String get scanComplete => _getString('scanComplete');
  String get scanFailed => _getString('scanFailed');
  String get tryAgain => _getString('tryAgain');
  String get saveToLibrary => _getString('saveToLibrary');

  // Reader
  String get readAloud => _getString('readAloud');
  String get pause => _getString('pause');
  String get resume => _getString('resume');
  String get stop => _getString('stop');
  String get previousSentence => _getString('previousSentence');
  String get nextSentence => _getString('nextSentence');
  String get readingSpeed => _getString('readingSpeed');
  String get slow => _getString('slow');
  String get normal => _getString('normal');
  String get fast => _getString('fast');
  String get pitch => _getString('pitch');
  String get volume => _getString('volume');

  // Settings
  String get accessibilitySettings => _getString('accessibilitySettings');
  String get highContrastMode => _getString('highContrastMode');
  String get largeText => _getString('largeText');
  String get textScaling => _getString('textScaling');
  String get ttsSettings => _getString('ttsSettings');
  String get voiceSelection => _getString('voiceSelection');
  String get languageChange => _getString('languageChange');
  String get currentLanguage => _getString('currentLanguage');
  String get changeLanguage => _getString('changeLanguage');

  // Accessibility
  String get accessibilityLabel => _getString('accessibilityLabel');
  String get progressAnnouncement => _getString('progressAnnouncement');
  String get buttonPressed => _getString('buttonPressed');
  String get pageLoaded => _getString('pageLoaded');
  String get documentReady => _getString('documentReady');

  String getString(String key) => _getString(key);

  String _getString(String key) {
    switch (language) {
      case AppLanguage.persian:
        return _faStrings[key] ?? '[$key]';
      case AppLanguage.dutch:
        return _nlStrings[key] ?? '[$key]';
      case AppLanguage.arabic:
        return _arStrings[key] ?? '[$key]';
      case AppLanguage.english:
        return _enStrings[key] ?? '[$key]';
    }
  }

  // Persian (Farsi) strings
  static const Map<String, String> _faStrings = {
    'appName': 'جست‌او‌سی‌آر',
    'welcome': 'خوش آمدید',
    'loading': 'در حال بارگذاری...',
    'error': 'خطا',
    'retry': 'تلاش مجدد',
    'cancel': 'لغو',
    'confirm': 'تأیید',
    'done': 'انجام شد',
    'settings': 'تنظیمات',
    'close': 'بستن',
    'selectLanguage': 'انتخاب زبان',
    'chooseLanguage': 'زبان برنامه خود را انتخاب کنید',
    'languageDescription': 'این برنامه از چهار زبان پشتیبانی می‌کند. زبان مورد نظر خود را انتخاب کنید.',
    'continueText': 'ادامه',
    'loginTitle': 'ورود به حساب',
    'loginSubtitle': 'برای شروع با حساب گوگل خود وارد شوید',
    'loginWithGoogle': 'ورود با گوگل',
    'apiKeySetupTitle': 'تنظیم کلید API',
    'apiKeyInstructions': 'برای استفاده از برنامه، باید کلید API گوگل خود را ایجاد کنید. مراحل زیر را دنبال کنید:',
    'step1': '۱. روی دکمه «باز کردن لینک» کلیک کنید',
    'step2': '۲. وارد حساب گوگل خود شوید (اگر نشده‌اید)',
    'step3': '۳. روی دکمه «Create API Key» کلیک کنید',
    'step4': '۴. کلید API را کپی کنید',
    'step5': '۵. کلید را در کادر زیر جایگذاری کرده و «کپی کردم» را بزنید',
    'openLink': 'باز کردن لینک',
    'iCopiedKey': 'کپی کردم',
    'pasteApiKey': 'کلید API را اینجا جایگذاری کنید',
    'apiKeyHint': 'کلید API خود را وارد کنید',
    'saveApiKey': 'ذخیره کلید API',
    'accountSection': 'حساب کاربری',
    'signedInAs': 'وارد شده به عنوان',
    'notSignedIn': 'وارد نشده',
    'setupApiKey': 'تنظیم کلید API',
    'signOut': 'خروج',
    'apiKeySaved': 'کلید API ذخیره شد',
    'loginRequired': 'برای استفاده از اسکن ابری، باید وارد حساب گوگل خود شوید.',
    'apiKey': 'کلید API',
    'configured': 'تنظیم شده',
    'notConfigured': 'تنظیم نشده',
    'booksTab': 'کتاب‌ها',
    'scanTab': 'اسکن',
    'profileTab': 'پروفایل',
    'myBooks': 'کتاب‌های من',
    'noBooks': 'هیچ کتابی وجود ندارد',
    'addBook': 'افزودن کتاب',
    'searchBooks': 'جستجوی کتاب‌ها',
    'bookTitle': 'عنوان کتاب',
    'lastRead': 'آخرین مطالعه',
    'readingProgress': 'پیشرفت مطالعه',
    'scanDocument': 'اسکن سند',
    'takePhoto': 'گرفتن عکس',
    'chooseFromGallery': 'انتخاب از گالری',
    'importFile': 'وارد کردن فایل',
    'scanning': 'در حال اسکن...',
    'processing': 'در حال پردازش...',
    'scanComplete': 'اسکن کامل شد',
    'scanFailed': 'اسکن ناموفق بود',
    'tryAgain': 'تلاش مجدد',
    'saveToLibrary': 'ذخیره در کتابخانه',
    'readAloud': 'بلندخوانی',
    'pause': 'توقف',
    'resume': 'ادامه',
    'stop': 'توقف کامل',
    'previousSentence': 'جمله قبلی',
    'nextSentence': 'جمله بعدی',
    'readingSpeed': 'سرعت خواندن',
    'slow': 'آهسته',
    'normal': 'عادی',
    'fast': 'سریع',
    'pitch': 'زیروبمی صدا',
    'volume': 'بلندی صدا',
    'accessibilitySettings': 'تنظیمات دسترسی',
    'highContrastMode': 'حالت کنتراست بالا',
    'largeText': 'متن بزرگ',
    'textScaling': 'مقیاس متن',
    'ttsSettings': 'تنظیمات تبدیل متن به گفتار',
    'voiceSelection': 'انتخاب صدا',
    'languageChange': 'تغییر زبان',
    'currentLanguage': 'زبان فعلی',
    'changeLanguage': 'تغییر زبان',
    'accessibilityLabel': 'برچسب دسترسی',
    'progressAnnouncement': 'اعلام پیشرفت',
    'buttonPressed': 'دکمه فشرده شد',
    'pageLoaded': 'صفحه بارگذاری شد',
    'documentReady': 'سند آماده است',
  };

  // Dutch strings
  static const Map<String, String> _nlStrings = {
    'appName': 'justOCR',
    'welcome': 'Welkom',
    'loading': 'Laden...',
    'error': 'Fout',
    'retry': 'Opnieuw proberen',
    'cancel': 'Annuleren',
    'confirm': 'Bevestigen',
    'done': 'Klaar',
    'settings': 'Instellingen',
    'close': 'Sluiten',
    'selectLanguage': 'Taal selecteren',
    'chooseLanguage': 'Kies de taal van uw app',
    'languageDescription': 'Deze app ondersteunt vier talen. Kies uw voorkeurstaal.',
    'continueText': 'Doorgaan',
    'loginTitle': 'Inloggen',
    'loginSubtitle': 'Log in met uw Google-account om te beginnen',
    'loginWithGoogle': 'Inloggen met Google',
    'apiKeySetupTitle': 'API-sleutel instellen',
    'apiKeyInstructions': 'Om deze app te gebruiken, moet u uw eigen Google API-sleutel maken. Volg deze stappen:',
    'step1': '1. Klik op de knop "Link openen"',
    'step2': '2. Log in op uw Google-account (indien nodig)',
    'step3': '3. Klik op de knop "Create API Key"',
    'step4': '4. Kopieer de API-sleutel',
    'step5': '5. Plak de sleutel in het onderstaande vak en klik op "Ik heb gekopieerd"',
    'openLink': 'Link openen',
    'iCopiedKey': 'Ik heb gekopieerd',
    'pasteApiKey': 'Plak hier uw API-sleutel',
    'apiKeyHint': 'Voer uw API-sleutel in',
    'saveApiKey': 'API-sleutel opslaan',
    'accountSection': 'Account',
    'signedInAs': 'Ingelogd als',
    'notSignedIn': 'Niet ingelogd',
    'setupApiKey': 'API-sleutel instellen',
    'signOut': 'Uitloggen',
    'apiKeySaved': 'API-sleutel opgeslagen',
    'loginRequired': 'Om cloudscanning te gebruiken, moet u ingelogd zijn met uw Google-account.',
    'apiKey': 'API-sleutel',
    'configured': 'Geconfigureerd',
    'notConfigured': 'Niet geconfigureerd',
    'booksTab': 'Boeken',
    'scanTab': 'Scannen',
    'profileTab': 'Profiel',
    'myBooks': 'Mijn boeken',
    'noBooks': 'Geen boeken',
    'addBook': 'Boek toevoegen',
    'searchBooks': 'Boeken zoeken',
    'bookTitle': 'Boektitel',
    'lastRead': 'Laatst gelezen',
    'readingProgress': 'Leesvoortgang',
    'scanDocument': 'Document scannen',
    'takePhoto': 'Foto maken',
    'chooseFromGallery': 'Kiezen uit galerij',
    'importFile': 'Bestand importeren',
    'scanning': 'Scannen...',
    'processing': 'Verwerken...',
    'scanComplete': 'Scannen voltooid',
    'scanFailed': 'Scannen mislukt',
    'tryAgain': 'Opnieuw proberen',
    'saveToLibrary': 'Opslaan in bibliotheek',
    'readAloud': 'Voorlezen',
    'pause': 'Pauzeren',
    'resume': 'Hervatten',
    'stop': 'Stoppen',
    'previousSentence': 'Vorige zin',
    'nextSentence': 'Volgende zin',
    'readingSpeed': 'Leessnelheid',
    'slow': 'Langzaam',
    'normal': 'Normaal',
    'fast': 'Snel',
    'pitch': 'Toonhoogte',
    'volume': 'Volume',
    'accessibilitySettings': 'Toegankelijkheidsinstellingen',
    'highContrastMode': 'Hoog contrastmodus',
    'largeText': 'Grote tekst',
    'textScaling': 'Tekstschaling',
    'ttsSettings': 'TTS-instellingen',
    'voiceSelection': 'Stemselectie',
    'languageChange': 'Taal wijzigen',
    'currentLanguage': 'Huidige taal',
    'changeLanguage': 'Taal wijzigen',
    'accessibilityLabel': 'Toegankelijkheidslabel',
    'progressAnnouncement': 'Voortgangsmededeling',
    'buttonPressed': 'Knop ingedrukt',
    'pageLoaded': 'Pagina geladen',
    'documentReady': 'Document klaar',
  };

  // Arabic strings
  static const Map<String, String> _arStrings = {
    'appName': 'جست‌أو‌سي‌آر',
    'welcome': 'مرحباً',
    'loading': 'جاري التحميل...',
    'error': 'خطأ',
    'retry': 'إعادة المحاولة',
    'cancel': 'إلغاء',
    'confirm': 'تأكيد',
    'done': 'تم',
    'settings': 'الإعدادات',
    'close': 'إغلاق',
    'selectLanguage': 'اختر اللغة',
    'chooseLanguage': 'اختر لغة التطبيق',
    'languageDescription': 'يدعم هذا التطبيق أربع لغات. اختر لغتك المفضلة.',
    'continueText': 'متابعة',
    'loginTitle': 'تسجيل الدخول',
    'loginSubtitle': 'سجل الدخول بحساب جوجل الخاص بك للبدء',
    'loginWithGoogle': 'تسجيل الدخول باستخدام جوجل',
    'apiKeySetupTitle': 'إعداد مفتاح API',
    'apiKeyInstructions': 'لاستخدام هذا التطبيق، يجب عليك إنشاء مفتاح API الخاص بجوجل. اتبع هذه الخطوات:',
    'step1': '١. انقر على زر "فتح الرابط"',
    'step2': '٢. سجل الدخول إلى حساب جوجل الخاص بك (إذا لزم الأمر)',
    'step3': '٣. انقر على زر "Create API Key"',
    'step4': '٤. انسخ مفتاح API',
    'step5': '٥. الصق المفتاح في المربع أدناه وانقر على "لقد نسخت"',
    'openLink': 'فتح الرابط',
    'iCopiedKey': 'لقد نسخت',
    'pasteApiKey': 'الصق مفتاح API هنا',
    'apiKeyHint': 'أدخل مفتاح API الخاص بك',
    'saveApiKey': 'حفظ مفتاح API',
    'accountSection': 'الحساب',
    'signedInAs': 'مسجل الدخول كـ',
    'notSignedIn': 'غير مسجل الدخول',
    'setupApiKey': 'إعداد مفتاح API',
    'signOut': 'تسجيل الخروج',
    'apiKeySaved': 'تم حفظ مفتاح API',
    'loginRequired': 'لاستخدام المسح السحابي، يجب أن تكون مسجل الدخول بحساب Google الخاص بك.',
    'apiKey': 'مفتاح API',
    'configured': 'تم التكوين',
    'notConfigured': 'غير مكوّن',
    'booksTab': 'الكتب',
    'scanTab': 'مسح',
    'profileTab': 'الملف الشخصي',
    'myBooks': 'كتبي',
    'noBooks': 'لا توجد كتب',
    'addBook': 'إضافة كتاب',
    'searchBooks': 'البحث عن الكتب',
    'bookTitle': 'عنوان الكتاب',
    'lastRead': 'آخر قراءة',
    'readingProgress': 'تقدم القراءة',
    'scanDocument': 'مسح المستند',
    'takePhoto': 'التقاط صورة',
    'chooseFromGallery': 'الاختيار من المعرض',
    'importFile': 'استيراد ملف',
    'scanning': 'جاري المسح...',
    'processing': 'جاري المعالجة...',
    'scanComplete': 'اكتمل المسح',
    'scanFailed': 'فشل المسح',
    'tryAgain': 'إعادة المحاولة',
    'saveToLibrary': 'حفظ في المكتبة',
    'readAloud': 'القراءة بصوت عالٍ',
    'pause': 'إيقاف مؤقت',
    'resume': 'استئناف',
    'stop': 'إيقاف',
    'previousSentence': 'الجملة السابقة',
    'nextSentence': 'الجملة التالية',
    'readingSpeed': 'سرعة القراءة',
    'slow': 'بطيء',
    'normal': 'عادي',
    'fast': 'سريع',
    'pitch': 'درجة الصوت',
    'volume': 'مستوى الصوت',
    'accessibilitySettings': 'إعدادات إمكانية الوصول',
    'highContrastMode': 'وضع التباين العالي',
    'largeText': 'نص كبير',
    'textScaling': 'تحجيم النص',
    'ttsSettings': 'إعدادات تحويل النص إلى كلام',
    'voiceSelection': 'اختيار الصوت',
    'languageChange': 'تغيير اللغة',
    'currentLanguage': 'اللغة الحالية',
    'changeLanguage': 'تغيير اللغة',
    'accessibilityLabel': 'تسمية إمكانية الوصول',
    'progressAnnouncement': 'إعلان التقدم',
    'buttonPressed': 'تم ضغط الزر',
    'pageLoaded': 'تم تحميل الصفحة',
    'documentReady': 'المستند جاهز',
  };

  // English strings
  static const Map<String, String> _enStrings = {
    'appName': 'justOCR',
    'welcome': 'Welcome',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'done': 'Done',
    'settings': 'Settings',
    'close': 'Close',
    'selectLanguage': 'Select Language',
    'chooseLanguage': 'Choose your app language',
    'languageDescription': 'This app supports four languages. Select your preferred language.',
    'continueText': 'Continue',
    'loginTitle': 'Sign In',
    'loginSubtitle': 'Sign in with your Google account to get started',
    'loginWithGoogle': 'Sign in with Google',
    'apiKeySetupTitle': 'Set Up API Key',
    'apiKeyInstructions': 'To use this app, you need to create your own Google API key. Follow these steps:',
    'step1': '1. Click the "Open Link" button',
    'step2': '2. Sign in to your Google account (if needed)',
    'step3': '3. Click the "Create API Key" button',
    'step4': '4. Copy the API key',
    'step5': '5. Paste the key in the box below and tap "I Copied"',
    'openLink': 'Open Link',
    'iCopiedKey': 'I Copied',
    'pasteApiKey': 'Paste your API key here',
    'apiKeyHint': 'Enter your API key',
    'saveApiKey': 'Save API Key',
    'accountSection': 'Account',
    'signedInAs': 'Signed in as',
    'notSignedIn': 'Not signed in',
    'setupApiKey': 'Set up API Key',
    'signOut': 'Sign out',
    'apiKeySaved': 'API key saved',
    'loginRequired': 'To use cloud scanning, you must be signed in to your Google account.',
    'apiKey': 'API Key',
    'configured': 'Configured',
    'notConfigured': 'Not configured',
    'booksTab': 'Books',
    'scanTab': 'Scan',
    'profileTab': 'Profile',
    'myBooks': 'My Books',
    'noBooks': 'No books',
    'addBook': 'Add Book',
    'searchBooks': 'Search books',
    'bookTitle': 'Book title',
    'lastRead': 'Last read',
    'readingProgress': 'Reading progress',
    'scanDocument': 'Scan Document',
    'takePhoto': 'Take Photo',
    'chooseFromGallery': 'Choose from Gallery',
    'importFile': 'Import File',
    'scanning': 'Scanning...',
    'processing': 'Processing...',
    'scanComplete': 'Scan complete',
    'scanFailed': 'Scan failed',
    'tryAgain': 'Try Again',
    'saveToLibrary': 'Save to Library',
    'readAloud': 'Read Aloud',
    'pause': 'Pause',
    'resume': 'Resume',
    'stop': 'Stop',
    'previousSentence': 'Previous sentence',
    'nextSentence': 'Next sentence',
    'readingSpeed': 'Reading speed',
    'slow': 'Slow',
    'normal': 'Normal',
    'fast': 'Fast',
    'pitch': 'Pitch',
    'volume': 'Volume',
    'accessibilitySettings': 'Accessibility Settings',
    'highContrastMode': 'High Contrast Mode',
    'largeText': 'Large Text',
    'textScaling': 'Text Scaling',
    'ttsSettings': 'TTS Settings',
    'voiceSelection': 'Voice Selection',
    'languageChange': 'Change Language',
    'currentLanguage': 'Current Language',
    'changeLanguage': 'Change Language',
    'accessibilityLabel': 'Accessibility Label',
    'progressAnnouncement': 'Progress Announcement',
    'buttonPressed': 'Button pressed',
    'pageLoaded': 'Page loaded',
    'documentReady': 'Document ready',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fa', 'nl', 'ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLanguage language;
    switch (locale.languageCode) {
      case 'fa':
        language = AppLanguage.persian;
        break;
      case 'nl':
        language = AppLanguage.dutch;
        break;
      case 'ar':
        language = AppLanguage.arabic;
        break;
      default:
        language = AppLanguage.english;
    }
    return AppLocalizations(language);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
