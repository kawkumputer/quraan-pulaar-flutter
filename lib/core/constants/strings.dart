import '../l10n/app_language.dart';
import '../models/surah_model.dart';

/// Tous les textes de l'interface, en trois langues : _t(pulaar, français, arabe).
///
/// À REMPLACER / VALIDER :
///  - français et arabe : brouillons à remplacer par vos traductions ;
///  - Pulaar ajouté depuis la 2.11 (réglages, lecture, audio, téléchargements) :
///    propositions à faire relire.
/// Le texte du Coran (arabe + traduction Pulaar) n'est pas concerné.
class S {
  static String _t(String ff, String fr, String ar) => switch (CurrentLanguage.value) {
        AppLanguage.pulaar => ff,
        AppLanguage.french => fr,
        AppLanguage.arabic => ar,
      };

  /// Nom d'une sourate selon la langue : arabe en interface arabe, sinon translittération.
  static String surahName(SurahModel s) =>
      CurrentLanguage.value == AppLanguage.arabic ? s.nameArabic : s.namePulaar;

  // ---------------------------------------------------------------------------
  // Langue
  // ---------------------------------------------------------------------------
  static String get language => _t('Ɗemngal', 'Langue', 'اللغة');
  static String get chooseLanguage => _t('Suɓo ɗemngal maa', 'Choisissez votre langue', 'اختر لغتك');
  static String get chooseLanguageHint =>
      _t('A waawi waylude ɗum e Teelte', 'Vous pourrez la changer dans les paramètres', 'يمكنك تغييرها لاحقاً من الإعدادات');
  static String get continueButton => _t('Jokku', 'Continuer', 'متابعة');

  // ---------------------------------------------------------------------------
  // Accueil et navigation
  // ---------------------------------------------------------------------------
  static String get surahs => _t('Cimooje', 'Sourates', 'السور');
  static String get surahsSubtitle => _t('Yiy cimooje ɗe fof', 'Voir toutes les sourates', 'عرض جميع السور');
  static String get hadithsMenu => _t('Njangtuuji (Hadiisaaji)', 'Hadiths', 'الأحاديث');
  static String get hadithsSubtitle => _t('Heɗto njangtuuji nulaaɗo', 'Écouter les hadiths du Prophète', 'استمع إلى أحاديث النبي ﷺ');
  static String get bookmarksMenu => _t('Maanto', 'Favoris', 'المفضلة');
  static String get bookmarksSubtitle => _t('Yiy cimooje ɗe maanitiɗa', 'Voir vos favoris', 'عرض المفضلة');
  static String get search => _t('Yiylo', 'Rechercher', 'بحث');
  static String get searchSubtitle =>
      _t('Yiylo cimooje walla maandeeji', 'Rechercher une sourate ou un verset', 'ابحث عن سورة أو آية');
  static String get contact => _t('Jokkondiral', 'Contact', 'اتصل بنا');
  static String get settings => _t('Teelte', 'Paramètres', 'الإعدادات');
  static String get activate => _t('Huuɓnu', 'Activer', 'تفعيل');
  static String get activated => _t('Huuɓnaama', 'Activée', 'مفعّلة');
  static String get unlockAll => _t('Huuɓnu haa timma', 'Tout débloquer', 'فتح الكل');
  static String get freeVersion => _t('Yamre Ɓolnde', 'Version gratuite', 'النسخة المجانية');
  static String get fullVersion => _t('Yamre Huuɓtunde', 'Version complète', 'النسخة الكاملة');
  static String get freeSurahsBanner => _t(
      'Njogiɗaa tan ko cimooje nay. Huuɓnu ngam keɓa cimooje ɗee kala.',
      "Vous avez accès à 4 sourates. Activez l'application pour toutes les obtenir.",
      'يمكنك الوصول إلى 4 سور فقط. فعّل التطبيق للحصول على جميع السور.');
  static String versesCount(int n) => _t('Maandeeji $n', '$n versets', '$n آيات');
  static String surahN(int n) => _t('Simoore $n', 'Sourate $n', 'سورة $n');

  // ---------------------------------------------------------------------------
  // Verset du jour, lecture
  // ---------------------------------------------------------------------------
  static String get dailyVerse => _t('Maande hannde ko', 'Verset du jour', 'آية اليوم');
  static String get dailyVerseError =>
      _t('Roŋkii heɓde maande hannde', "Impossible d'afficher le verset du jour", 'تعذر عرض آية اليوم');
  static String get verse => _t('Maande', 'Verset', 'الآية');
  static String verseRef(SurahModel s, int verseNumber) => '${surahName(s)} · $verse $verseNumber';
  static String get source => _t('Ummoraade e Quraan Pulaar', 'Source : Quraan Pulaar', 'المصدر: تطبيق Quraan Pulaar');
  static String get continueReading => _t('Jokku jaŋngude', 'Reprendre la lecture', 'متابعة القراءة');
  static String get playFromHere => _t('Heɗaade fuɗɗode ɗoo', "Écouter à partir d'ici", 'الاستماع من هنا');
  static String get bookmarkVerse => _t('Maantu maande nde', 'Ajouter le verset aux favoris', 'إضافة الآية إلى المفضلة');
  static String get removeVerseBookmark =>
      _t('Itto maantol maande nde', 'Retirer le verset des favoris', 'إزالة الآية من المفضلة');
  static String get copy => _t('Natto', 'Copier', 'نسخ');
  static String get copied => _t('Maande nde nattaama', 'Verset copié', 'تم نسخ الآية');
  static String get share => _t('Yaltinde', 'Partager', 'مشاركة');
  static String get versesComing =>
      _t('Maa maandeeji ɗi ɓeydoye ɗoo e yeeso', 'Les versets seront bientôt ajoutés', 'ستُضاف الآيات قريباً');
  static String get deleteDownloadTitle => _t('Momtu Simoore', 'Supprimer le téléchargement', 'حذف التنزيل');
  static String get deleteDownloadConfirm =>
      _t('Aɗa yiɗi momtude simoore nde?', 'Supprimer cette sourate téléchargée ?', 'هل تريد حذف هذه السورة المنزّلة؟');
  static String get downloadFailed => _t('Roŋki aawde simoore nde', 'Échec du téléchargement', 'فشل التنزيل');

  // ---------------------------------------------------------------------------
  // Favoris
  // ---------------------------------------------------------------------------
  static String get bookmarksTitle => _t('Maantaaɗi', 'Favoris', 'المفضلة');
  static String get bookmarkedVerses => _t('Maandeeji maantaaɗi', 'Versets favoris', 'الآيات المفضلة');
  static String get bookmarkedSurahs => _t('Cimooje maantaaɗe', 'Sourates favorites', 'السور المفضلة');
  static String get noBookmarks => _t('A suwa maantaade tawo', "Aucun favori pour l'instant", 'لا توجد مفضلة بعد');
  static String get noBookmarksHint => _t('Cimooje ɗe maanti ɗaa maa a yiy ɗum en ɗo',
      'Les sourates et versets ajoutés aux favoris apparaîtront ici', 'ستظهر هنا السور والآيات التي تضيفها إلى المفضلة');
  static String get surahBookmarked =>
      _t('Simoore nde ɓeydaama e maantaaɗi', 'Sourate ajoutée aux favoris', 'أُضيفت السورة إلى المفضلة');
  static String get surahUnbookmarked =>
      _t('Simoore nde ittaama e maantaaɗi', 'Sourate retirée des favoris', 'أُزيلت السورة من المفضلة');

  // ---------------------------------------------------------------------------
  // Recherche
  // ---------------------------------------------------------------------------
  static String get searchTitle => _t('Yiylo cimooje', 'Rechercher', 'البحث');
  static String get searchHint => _t('Yiylo simoore walla maande…', 'Rechercher une sourate ou un verset…', 'ابحث عن سورة أو آية…');
  static String get noResults => _t('Alaa ko heɓaa', 'Aucun résultat', 'لا توجد نتائج');

  // ---------------------------------------------------------------------------
  // Hadiths
  // ---------------------------------------------------------------------------
  static String get hadithsTitle => _t('Hadiisaaji', 'Hadiths', 'الأحاديث');
  static String hadithN(int n) => _t('Njangtuwol $n', 'Hadith $n', 'الحديث $n');
  static String get noHadiths => _t('Alaa hadiisaaji goodɗi', 'Aucun hadith disponible', 'لا توجد أحاديث متاحة');
  static String get hadithLocked =>
      _t('Huuɓnu ngam heɗaade hadiisa oo', 'Activez pour écouter ce hadith', 'فعّل التطبيق للاستماع إلى هذا الحديث');
  static String get freeHadithsBanner => _t(
      'Njogiɗaa tan ko njangtuuji (Hadisaaji) tati. Huuɓnu ngam keɓa njangtuuji nulaaɗo ɗii kala.',
      "Vous avez accès à 3 hadiths. Activez l'application pour tous les écouter.",
      'يمكنك الوصول إلى 3 أحاديث فقط. فعّل التطبيق للاستماع إليها جميعاً.');

  // ---------------------------------------------------------------------------
  // Activation
  // ---------------------------------------------------------------------------
  static String get activationTitle => _t('Kuuɓnugol', 'Activation', 'التفعيل');
  static String get activationWelcome => _t(
      'A jaɓɓaama e Quraan Pulaar!\n\nHuuɓnu jaaɓnirgal ngal ngam heɓde cimooje ɗee fof. So a huuɓnaani, ko cimooje nay tan keɓataa.',
      "Bienvenue dans Quraan Pulaar !\n\nActivez l'application pour accéder à toutes les sourates. Sans activation, seules 4 sourates sont disponibles.",
      'مرحباً بك في Quraan Pulaar!\n\nفعّل التطبيق للوصول إلى جميع السور. بدون تفعيل تتوفر 4 سور فقط.');
  static String get activationScreenText => _t(
      'Naatnu doggol kuuɓnugol ngam heɓde cimooje ɗee fof.\nSo a huuɓnaani, cimooje nay tan keɓataa.',
      "Saisissez votre code d'activation pour accéder à toutes les sourates.\nSans activation, seules 4 sourates sont disponibles.",
      'أدخل رمز التفعيل للوصول إلى جميع السور.\nبدون تفعيل تتوفر 4 سور فقط.');
  static String get activationCode => _t('Doggol Kuuɓnugol', "Code d'activation", 'رمز التفعيل');
  static String get activationCodeHint => _t('Naatnu doggol maa', 'Saisissez votre code', 'أدخل الرمز');
  static String get tryFree => _t('Eto ƴeewndagol', 'Essayer gratuitement', 'جرّب مجاناً');
  static String get notNow => _t('Goɗngol', 'Plus tard', 'لاحقاً');
  static String get pleaseWait => _t('Sabbo seeɗa...', 'Patientez…', 'يرجى الانتظار…');
  static String get noCodeContact =>
      _t('So tawi a alaa doggol kuuɓnugol, yah to ', "Si vous n'avez pas de code, allez dans ", 'إذا لم يكن لديك رمز، انتقل إلى ');
  static String get enterCode =>
      _t('Tiiɗno naatnu doggol Kuuɓnugol', "Veuillez saisir le code d'activation", 'يرجى إدخال رمز التفعيل');
  static String get activationSuccess =>
      _t('Kaɓirgal ngal huuɓnaama no moƴƴiri', 'Appareil activé avec succès', 'تم تفعيل الجهاز بنجاح');
  static String get activationFailed => _t('Roŋki huuɓnude kaɓirgal ngal, ƴeewto tawo doggol ngol ina moƴƴi',
      'Activation impossible. Vérifiez votre code.', 'تعذر التفعيل. تحقق من الرمز.');
  static String get activateDevice => _t('Kuɓnugol Kaɓirgal', "Activer l'appareil", 'تفعيل الجهاز');

  // ---------------------------------------------------------------------------
  // À propos (écran bilingue : le Pulaar est conservé en interface arabe)
  // ---------------------------------------------------------------------------
  static String get aboutTranslation => _t(
      'Ngal jaaɓngal tuugnii ko e deftere Quraan teddunde nde ceerno Abuu Sih firi he ɗemngal Pulaar Fulfulde',
      "Cette application s'appuie sur la traduction du Saint Coran en pulaar (fulfulde) de Cerno Abuu Sih",
      'Ngal jaaɓngal tuugnii ko e deftere Quraan teddunde nde ceerno Abuu Sih firi he ɗemngal Pulaar Fulfulde');
  static String get aboutDeveloper => _t('Baañnjitiiɗo deftere nde e mbaaydi jaaɓngal ko Hamath Kan',
      'Application développée par Hamath Kan', 'Baañnjitiiɗo deftere nde e mbaaydi jaaɓngal ko Hamath Kan');
  static String get contactBilingual => _t('Jokkondir - اتصل', 'Contact - اتصل', 'اتصل بنا');

  // ---------------------------------------------------------------------------
  // Réglages
  // ---------------------------------------------------------------------------
  static String get theme => _t('Goobu', 'Thème', 'المظهر');
  static String get themeSystem => _t('Wano kaɓirgal', 'Comme le téléphone', 'حسب الهاتف');
  static String get themeLight => _t('Jalbugol', 'Clair', 'فاتح');
  static String get themeDark => _t('Niɓɓiɗgol', 'Sombre', 'داكن');
  static String get fontSize => _t('Ɓeydugol binndi', 'Taille du texte', 'حجم الخط');

  /// Aperçu de la traduction Pulaar (toujours en Pulaar : c'est le texte des versets).
  static const fontPreview = 'E innde Alla Jurumdeero Jurmotooɗo';
  static String get surahOrder => _t('Doggol cimooje', 'Ordre des sourates', 'ترتيب السور');
  static String get reminder => _t('Ciftinal maande ñalnde', 'Rappel quotidien', 'تذكير يومي');
  static String get reminderPermissionDenied => _t(
      'Yamir tintine ngal e teelte kaɓirgal maa ngam heɓde ciftinal',
      'Autorisez les notifications dans les réglages du téléphone pour recevoir le rappel.',
      'اسمح بالإشعارات في إعدادات الهاتف لتلقي التذكير.');
  static String get reminderChannelDescription =>
      _t('Ciftinal maande hannde', 'Rappel du verset du jour', 'تذكير بآية اليوم');
  static String get shareText => _t('Jaŋngu Quraan e Pulaar e Quraan Pulaar',
      'Lisez et écoutez le Coran en pulaar avec Quraan Pulaar', 'اقرأ واستمع إلى القرآن بالبولارية مع Quraan Pulaar');

  // ---------------------------------------------------------------------------
  // États, erreurs
  // ---------------------------------------------------------------------------
  static String get loadError => _t('Roŋkii loowde cimooje ɗee', 'Impossible de charger les sourates', 'تعذر تحميل السور');
  static String get noSurahs => _t('Alaa simoore yiytaama', 'Aucune sourate trouvée', 'لم يتم العثور على سور');
  static String get retry => _t('Fuɗɗito', 'Réessayer', 'إعادة المحاولة');
  static String get genericError => _t('Juumre waɗii, fuɗɗito', 'Une erreur est survenue, réessayez', 'حدث خطأ، حاول مرة أخرى');
  static String get noConnection => _t('Alaa ceŋagol enternet', 'Pas de connexion internet', 'لا يوجد اتصال بالإنترنت');
  static String get noConnectionNotDownloaded => _t(
      'Alaa ceŋagol enternet. Aawto simoore nde ngam heɗaade nde tawa a ceŋaaki.',
      "Pas de connexion. Téléchargez cette sourate pour l'écouter hors ligne.",
      'لا يوجد اتصال. نزّل هذه السورة للاستماع إليها دون إنترنت.');
  static String get playSurahError => _t('Roŋki aawtaade simoore nde', 'Impossible de lire la sourate', 'تعذر تشغيل السورة');
  static String get playHadithError => _t('Roŋki aawtaade hadiisa nde', 'Impossible de lire le hadith', 'تعذر تشغيل الحديث');
  static String get offline => _t('A ceŋaaki e enternet', 'Vous êtes hors ligne', 'أنت غير متصل بالإنترنت');
  static String get later => _t('Ɓooyte', 'Plus tard', 'لاحقاً');
  static String get yes => _t('Eyy', 'Oui', 'نعم');
  static String get no => _t('Alaa', 'Non', 'لا');
  static String get cancel => _t('Haaytu', 'Annuler', 'إلغاء');

  // ---------------------------------------------------------------------------
  // Version minimale
  // ---------------------------------------------------------------------------
  static String get updateTitle => _t('Hesɗitin jaaɓngal ngal', "Mettre à jour l'application", 'تحديث التطبيق');
  static String get updateRequired => _t(
      'Jaaɓngal kesngal ina woodi. Hesɗitin ngal ngam jokkude huutoraade Quraan Pulaar.',
      'Une nouvelle version est disponible. Mettez à jour pour continuer à utiliser Quraan Pulaar.',
      'يتوفر إصدار جديد. حدّث التطبيق لمواصلة استخدام Quraan Pulaar.');
  static String get updateAvailable =>
      _t('Jaaɓngal kesngal ina woodi.', 'Une nouvelle version est disponible.', 'يتوفر إصدار جديد.');
  static String get updateButton => _t('Hesɗitin', 'Mettre à jour', 'تحديث');

  // ---------------------------------------------------------------------------
  // Audio, téléchargements
  // ---------------------------------------------------------------------------
  static String get speed => _t('Yaawre', 'Vitesse', 'السرعة');
  static String get repeat => _t('Fiilitde', 'Répéter', 'التكرار');
  static String get repeatOff => _t('Alaa', 'Non', 'إيقاف');
  static String get repeatItem => _t('Ndee simoore', 'Cette piste', 'هذا المقطع');
  static String get repeatVerse => _t('Ndee maande', 'Ce verset', 'هذه الآية');
  static String get sleepTimer => _t('Dartingol', 'Minuterie', 'مؤقت الإيقاف');
  static String get sleepEndOfItem => _t('Gasirde ndee', 'Fin de la piste', 'نهاية المقطع');
  static String get sleepAt => _t('Dartat ko', 'Pause à', 'إيقاف عند');
  static String minutes(int n) => _t('$n min', '$n min', '$n د');
  static String get downloads => _t('Aawtaaɗe', 'Téléchargements', 'التنزيلات');
  static String get downloadAll => _t('Aawto fof', 'Tout télécharger', 'تنزيل الكل');
  static String get deleteAll => _t('Momtu fof', 'Tout supprimer', 'حذف الكل');
  static String get deleteAllConfirm => _t('Aɗa yiɗi momtude cimooje aawtaaɗe ɗee fof?',
      'Supprimer toutes les sourates téléchargées ?', 'هل تريد حذف جميع السور المنزّلة؟');
  static String get wifiOnly => _t('Aawto e WiFi tan', 'Wi-Fi uniquement', 'عبر Wi-Fi فقط');
  static String get storageUsed => _t('Nokku huutoraaɗo', 'Espace utilisé', 'المساحة المستخدمة');
  static String get waitingNetwork => _t('Ina sabbo ceŋagol', 'En attente de réseau', 'في انتظار الشبكة');
}
