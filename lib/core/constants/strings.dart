import '../l10n/app_language.dart';
import '../models/surah_model.dart';

/// Tous les textes de l'interface, en trois langues : _t(pulaar, français, arabe).
///
/// Pulaar : relu et corrigé (document docs/Quraan_Pulaar_traduit.docx, 21/10/2026).
/// Français et arabe : brouillons, à valider.
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
  static String get chooseLanguage => _t('Suɓto ɗemngal ma', 'Choisissez votre langue', 'اختر لغتك');
  static String get chooseLanguageHint =>
      _t('Aɗa waawi waylude ɗum to Teelte', 'Vous pourrez la changer dans les paramètres', 'يمكنك تغييرها لاحقاً من الإعدادات');
  static String get continueButton => _t('Jokku', 'Continuer', 'متابعة');

  // ---------------------------------------------------------------------------
  // Accueil et navigation
  // ---------------------------------------------------------------------------
  static String get surahs => _t('Cimooje', 'Sourates', 'السور');
  static String get surahsSubtitle => _t('Yiy cimooje ɗe fof', 'Voir toutes les sourates', 'عرض جميع السور');
  static String get hadithsMenu => _t('Njangtuuji (Hadiisaaji)', 'Hadiths', 'الأحاديث');
  static String get hadithsSubtitle => _t('Heɗto njangtuuji nulaaɗo', 'Écouter les hadiths du Prophète', 'استمع إلى أحاديث النبي ﷺ');
  static String get bookmarksMenu => _t('Ɓuranɗi', 'Favoris', 'المفضلة');
  static String get bookmarksSubtitle => _t('Ndaar ɓuranɗi ma', 'Voir vos favoris', 'عرض المفضلة');
  static String get search => _t('Yiylo', 'Rechercher', 'بحث');
  static String get searchSubtitle =>
      _t('Yiylo cimooje walla maandeeji', 'Rechercher une sourate ou un verset', 'ابحث عن سورة أو آية');
  static String get contact => _t('Jokkondiral', 'Contact', 'اتصل بنا');
  static String get settings => _t('Teelte', 'Paramètres', 'الإعدادات');
  static String get activate => _t('Uddit', 'Activer', 'تفعيل');
  static String get activated => _t('Udditiima', 'Activée', 'مفعّلة');
  static String get unlockAll => _t('Loggit fof', 'Tout débloquer', 'فتح الكل');
  static String get freeVersion => _t('Lowre alaa njoɓdi', 'Version gratuite', 'النسخة المجانية');
  static String get fullVersion => _t('Lowre timmunde', 'Version complète', 'النسخة الكاملة');
  static String get freeSurahsBanner => _t(
      'Aɗa waawi ƴellitaade e cimooje 4, uddit jaaɓngal ngal ngam keɓaa cimooje ɗe kala.',
      "Vous avez accès à 4 sourates. Activez l'application pour toutes les obtenir.",
      'يمكنك الوصول إلى 4 سور فقط. فعّل التطبيق للحصول على جميع السور.');
  static String versesCount(int n) => _t('Maandeeji $n', '$n versets', '$n آيات');
  static String surahN(int n) => _t('Simoore $n', 'Sourate $n', 'سورة $n');

  // ---------------------------------------------------------------------------
  // Verset du jour, lecture
  // ---------------------------------------------------------------------------
  static String get dailyVerse => _t('Maande hannde', 'Verset du jour', 'آية اليوم');
  static String get dailyVerseError =>
      _t('Newotaako ɓannginde hannde simoore', "Impossible d'afficher le verset du jour", 'تعذر عرض آية اليوم');
  static String get verse => _t('Maande', 'Verset', 'الآية');
  static String verseRef(SurahModel s, int verseNumber) => '${surahName(s)} · $verse $verseNumber';
  static String get source => _t('Ummoraade e Quraan Pulaar', 'Source : Quraan Pulaar', 'المصدر: تطبيق Quraan Pulaar');
  static String get continueReading => _t('Fuɗɗito taro ngo', 'Reprendre la lecture', 'متابعة القراءة');
  static String get playFromHere => _t('Heɗaade gila fuɗɗoode ɗoo', "Écouter à partir d'ici", 'الاستماع من هنا');
  static String get bookmarkVerse => _t('Ɓeydit maande nde to ɓurnaaɗi', 'Ajouter le verset aux favoris', 'إضافة الآية إلى المفضلة');
  static String get removeVerseBookmark =>
      _t('Ittu maande nde to ɓurnaaɗi too.', 'Retirer le verset des favoris', 'إزالة الآية من المفضلة');
  static String get copy => _t('Waañnjito', 'Copier', 'نسخ');
  static String get copied => _t('Maande waañnjitaama', 'Verset copié', 'تم نسخ الآية');
  static String get share => _t('Saaktude', 'Partager', 'مشاركة');
  static String get versesComing =>
      _t('Maa maandeeji ɗi ɓeydoye ko neeɓaani', 'Les versets seront bientôt ajoutés', 'ستُضاف الآيات قريباً');
  static String get deleteDownloadTitle => _t('Moomtu aawtannde nde', 'Supprimer le téléchargement', 'حذف التنزيل');
  static String get deleteDownloadConfirm =>
      _t('Moomtu ndee simoore aawtaande', 'Supprimer cette sourate téléchargée ?', 'هل تريد حذف هذه السورة المنزّلة؟');
  static String get downloadFailed => _t('Gaawtagol ngol moccii', 'Échec du téléchargement', 'فشل التنزيل');

  // ---------------------------------------------------------------------------
  // Favoris
  // ---------------------------------------------------------------------------
  static String get bookmarksTitle => _t('Ɓuranɗi', 'Favoris', 'المفضلة');
  static String get bookmarkedVerses => _t('Maandeeji Ɓuranɗi', 'Versets favoris', 'الآيات المفضلة');
  static String get bookmarkedSurahs => _t('Cimooje Ɓurnaaɗe', 'Sourates favorites', 'السور المفضلة');
  static String get noBookmarks => _t('Alaa ɓurnaande nih jooni', "Aucun favori pour l'instant", 'لا توجد مفضلة بعد');
  static String get noBookmarksHint => _t('Cimooje e maandeeji ɓeydaaɗe to Ɓurnaaɗi ko ɗoo peeñata',
      'Les sourates et versets ajoutés aux favoris apparaîtront ici', 'ستظهر هنا السور والآيات التي تضيفها إلى المفضلة');
  static String get surahBookmarked =>
      _t('Simoore ɓeyditaande to Ɓurnaaɗe', 'Sourate ajoutée aux favoris', 'أُضيفت السورة إلى المفضلة');
  static String get surahUnbookmarked =>
      _t('Simoore roostaande to Ɓurnaaɗe', 'Sourate retirée des favoris', 'أُزيلت السورة من المفضلة');

  // ---------------------------------------------------------------------------
  // Recherche
  // ---------------------------------------------------------------------------
  static String get searchTitle => _t('Jiilagol', 'Rechercher', 'البحث');
  static String get searchHint => _t('Jiilagol Simoore walla Maande', 'Rechercher une sourate ou un verset…', 'ابحث عن سورة أو آية…');
  static String get noResults => _t('Alaa njeñtudi', 'Aucun résultat', 'لا توجد نتائج');

  // ---------------------------------------------------------------------------
  // Hadiths
  // ---------------------------------------------------------------------------
  static String get hadithsTitle => _t('Njangtuuji', 'Hadiths', 'الأحاديث');
  static String hadithN(int n) => _t('Njangtuwol $n', 'Hadith $n', 'الحديث $n');
  static String get noHadiths => _t('Alaa njangtuwol keɓingol', 'Aucun hadith disponible', 'لا توجد أحاديث متاحة');
  static String get hadithLocked =>
      _t('Uddit jaaɓngal ngal ngam heɗaade ngol njangtuwol', 'Activez pour écouter ce hadith', 'فعّل التطبيق للاستماع إلى هذا الحديث');
  static String get freeHadithsBanner => _t(
      'Njogiɗaa tan ko njangtuuji (Hadisaaji) tati. Huuɓnu ngam keɓa njangtuuji nulaaɗo ɗi kala.',
      "Vous avez accès à 3 hadiths. Activez l'application pour tous les écouter.",
      'يمكنك الوصول إلى 3 أحاديث فقط. فعّل التطبيق للاستماع إليها جميعاً.');

  // ---------------------------------------------------------------------------
  // Activation
  // ---------------------------------------------------------------------------
  static String get activationTitle => _t('Udditgol', 'Activation', 'التفعيل');
  static String get activationWelcome => _t(
      'A jaɓɓaama e Quraan Pulaar!\n\nHuuɓnu jaaɓnirgal ngal ngam heɓde cimooje ɗe fof. So a huuɓnaani, ko cimooje nay tan keɓataa.',
      "Bienvenue dans Quraan Pulaar !\n\nActivez l'application pour accéder à toutes les sourates. Sans activation, seules 4 sourates sont disponibles.",
      'مرحباً بك في Quraan Pulaar!\n\nفعّل التطبيق للوصول إلى جميع السور. بدون تفعيل تتوفر 4 سور فقط.');
  static String get activationScreenText => _t(
      'Naatnu maantoode Sirlu coftingol ma ngam keɓgol cimooje ɗe kala.\nSo softinaakam ko cimooje 4 tan newotoo',
      "Saisissez votre code d'activation pour accéder à toutes les sourates.\nSans activation, seules 4 sourates sont disponibles.",
      'أدخل رمز التفعيل للوصول إلى جميع السور.\nبدون تفعيل تتوفر 4 سور فقط.');
  static String get activationCode => _t('Maantoode coftingol', "Code d'activation", 'رمز التفعيل');
  static String get activationCodeHint => _t('Winndu maande coftingol', 'Saisissez votre code', 'أدخل الرمز');
  static String get tryFree => _t('Etoraade ɓolum', 'Essayer gratuitement', 'جرّب مجاناً');
  static String get notNow => _t('Neeɓataa', 'Plus tard', 'لاحقاً');
  static String get pleaseWait => _t('Sabbo seeɗa...', 'Patientez…', 'يرجى الانتظار…');
  static String get noCodeContact =>
      _t('So tawii a alaa maantoode sirlu, yah nder ', "Si vous n'avez pas de code, allez dans ", 'إذا لم يكن لديك رمز، انتقل إلى ');
  static String get enterCode =>
      _t('Winndu maantoode sirlu udditgol', "Veuillez saisir le code d'activation", 'يرجى إدخال رمز التفعيل');
  static String get activationSuccess =>
      _t('Cinndel ngel udditiima e wellet', 'Appareil activé avec succès', 'تم تفعيل الجهاز بنجاح');
  static String get activationFailed => _t('Newotaakoko udditgol. Ƴeewtindo maantoode ma',
      'Activation impossible. Vérifiez votre code.', 'تعذر التفعيل. تحقق من الرمز.');
  static String get activateDevice => _t('Uddit cinndel ngel', "Activer l'appareil", 'تفعيل الجهاز');

  // ---------------------------------------------------------------------------
  // Mon activation (Pulaar : brouillon, à relire)
  // ---------------------------------------------------------------------------
  static String get myActivation => _t('Coftingol am', 'Mon activation', 'تفعيلي');
  static String get activatedOn => _t('Udditaama ñalnde', 'Activé le', 'تم التفعيل في');
  static String get onDevice => _t('Cinndel', 'Appareil', 'الجهاز');
  static String get showCode => _t('Hollu maantoode', 'Afficher le code', 'إظهار الرمز');
  static String get keepCodeHint => _t(
      'Reen maantoode maa. Ina waɗɗii so a waylii cinndel.',
      'Gardez ce code : il vous sera demandé si vous changez de téléphone.',
      'احتفظ بهذا الرمز: سيُطلب منك إذا غيّرت هاتفك.');
  static String get changePhoneContact => _t(
      'Waylugol cinndel walla naamnal: haalan Abuu Sih e WhatsApp',
      'Changement de téléphone ou question : contactez Abou Sy sur WhatsApp',
      'لتغيير الهاتف أو لأي سؤال: تواصل مع أبو سي عبر واتساب');
  static String get buyCodeContact => _t(
      'Soodugol maantoode coftingol: haalan Abuu Sih e WhatsApp',
      "Pour obtenir un code d'activation : contactez Abou Sy sur WhatsApp",
      'للحصول على رمز التفعيل: تواصل مع أبو سي عبر واتساب');
  static String get contactWhatsapp => _t('Haalan e WhatsApp', 'Contacter sur WhatsApp', 'تواصل عبر واتساب');
  static String whatsappMessage(String code) => code.isEmpty
      ? _t('Jam, mi yiɗi soodude maantoode Quraan Pulaar.', 'Bonjour, je voudrais un code Quraan Pulaar.',
          'السلام عليكم، أريد رمز تفعيل Quraan Pulaar.')
      : _t('Jam, maantoode am Quraan Pulaar: $code', 'Bonjour, mon code Quraan Pulaar : $code',
          'السلام عليكم، رمز Quraan Pulaar الخاص بي: $code');

  // ---------------------------------------------------------------------------
  // À propos (écran bilingue : le Pulaar est conservé en interface arabe)
  // ---------------------------------------------------------------------------
  static String get aboutTranslation => _t(
      'Ngal jaaɓngal tuugnii ko e firo Quraan tedduɗo mo ceerno Abuu Sih firi he ɗemngal Pulaar Fulfulde',
      "Cette application s'appuie sur la traduction du Saint Coran en pulaar (fulfulde) de Cerno Abuu Sih",
      'Ngal jaaɓngal tuugnii ko e deftere Quraan teddunde nde ceerno Abuu Sih firi he ɗemngal Pulaar Fulfulde');
  static String get aboutDeveloper => _t('Baañnjitiiɗo deftere nde e mbaaydi jaaɓngal ko Hamath Kan',
      'Application développée par Hamath Kan', 'Baañnjitiiɗo deftere nde e mbaaydi jaaɓngal ko Hamath Kan');
  static String get contactBilingual => _t('Jokkondir', 'Contact - اتصل', 'اتصل بنا');

  // ---------------------------------------------------------------------------
  // Réglages
  // ---------------------------------------------------------------------------
  static String get theme => _t('Tiitoonde', 'Thème', 'المظهر');
  static String get themeSystem => _t('Hono no cinndel', 'Comme le téléphone', 'حسب الهاتف');
  static String get themeLight => _t('Jalbugol', 'Clair', 'فاتح');
  static String get themeDark => _t('Niɓɓiɗgol', 'Sombre', 'داكن');
  static String get fontSize => _t('Toowal winndannde nde', 'Taille du texte', 'حجم الخط');

  /// Aperçu de la traduction Pulaar (toujours en Pulaar : c'est le texte des versets).
  static const fontPreview = 'E innde Alla Jurumdeero Jurmotooɗo';
  static String get surahOrder => _t('Doggol cimooje', 'Ordre des sourates', 'ترتيب السور');
  static String get reminder => _t('Ciftingol ñande kala', 'Rappel quotidien', 'تذكير يومي');
  static String get reminderPermissionDenied => _t(
      'Yamir ciftinooje ɗe to nder njuɓɓinaaɗi telefon ngam keɓaa siftinoore',
      'Autorisez les notifications dans les réglages du téléphone pour recevoir le rappel.',
      'اسمح بالإشعارات في إعدادات الهاتف لتلقي التذكير.');
  static String get reminderChannelDescription =>
      _t('Siftinoore ñalaande nde', 'Rappel du verset du jour', 'تذكير بآية اليوم');
  static String get shareText => _t('Janngu kadi keɗoɗaa Alɓuraana he pulaar wondude e Quraan Pulaar',
      'Lisez et écoutez le Coran en pulaar avec Quraan Pulaar', 'اقرأ واستمع إلى القرآن بالبولارية مع Quraan Pulaar');

  // ---------------------------------------------------------------------------
  // États, erreurs
  // ---------------------------------------------------------------------------
  static String get loadError => _t('Newotaako waylude cimooje ɗe', 'Impossible de charger les sourates', 'تعذر تحميل السور');
  static String get noSurahs => _t('Hay simoore wootere yiytaaka', 'Aucune sourate trouvée', 'لم يتم العثور على سور');
  static String get retry => _t('Etito', 'Réessayer', 'إعادة المحاولة');
  static String get genericError => _t('Juumre heɓtiima etito', 'Une erreur est survenue, réessayez', 'حدث خطأ، حاول مرة أخرى');
  static String get noConnection => _t('Ala seŋaare enternet', 'Pas de connexion internet', 'لا يوجد اتصال بالإنترنت');
  static String get noConnectionNotDownloaded => _t(
      'Ceŋagol alaa. Aawto simoore nde ngam heɗaade nde tawa a seŋaaki.',
      "Pas de connexion. Téléchargez cette sourate pour l'écouter hors ligne.",
      'لا يوجد اتصال. نزّل هذه السورة للاستماع إليها دون إنترنت.');
  static String get playSurahError => _t('Newotaako tarde simoore nde', 'Impossible de lire la sourate', 'تعذر تشغيل السورة');
  static String get playHadithError => _t('Newotaako targol njangtu ngu', 'Impossible de lire le hadith', 'تعذر تشغيل الحديث');
  static String get offline => _t('A ceŋaaki e enternet', 'Vous êtes hors ligne', 'أنت غير متصل بالإنترنت');
  static String get later => _t('Neeɓataa', 'Plus tard', 'لاحقاً');
  static String get yes => _t('Eey', 'Oui', 'نعم');
  static String get no => _t('Alaa', 'Non', 'لا');
  static String get cancel => _t('Haaytu', 'Annuler', 'إلغاء');

  // ---------------------------------------------------------------------------
  // Version minimale
  // ---------------------------------------------------------------------------
  static String get updateTitle => _t('Hesɗitin jaaɓngal ngal', "Mettre à jour l'application", 'تحديث التطبيق');
  static String get updateRequired => _t(
      'Jaaɓngal kesal ina woodi. Hesɗitin ngal ngam jokkude huutoraade Quraan Pulaar.',
      'Une nouvelle version est disponible. Mettez à jour pour continuer à utiliser Quraan Pulaar.',
      'يتوفر إصدار جديد. حدّث التطبيق لمواصلة استخدام Quraan Pulaar.');
  static String get updateAvailable =>
      _t('Jaaɓngal kesal ina woodi.', 'Une nouvelle version est disponible.', 'يتوفر إصدار جديد.');
  static String get updateButton => _t('Hesɗitin', 'Mettre à jour', 'تحديث');

  // ---------------------------------------------------------------------------
  // Audio, téléchargements
  // ---------------------------------------------------------------------------
  static String get speed => _t('Lefu', 'Vitesse', 'السرعة');
  static String get repeat => _t('Fillitaade', 'Répéter', 'التكرار');
  static String get repeatOff => _t('Alaa', 'Non', 'إيقاف');
  static String get repeatItem => _t('Ngol bolol', 'Cette piste', 'هذا المقطع');
  static String get repeatVerse => _t('Ndee maande', 'Ce verset', 'هذه الآية');
  static String get sleepTimer => _t('Hojomere', 'Minuterie', 'مؤقت الإيقاف');
  static String get sleepEndOfItem => _t('Gasirde ndee', 'Fin de la piste', 'نهاية المقطع');
  static String get sleepAt => _t('Yowre', 'Pause à', 'إيقاف عند');
  static String minutes(int n) => _t('$n min', '$n min', '$n د');
  static String get downloads => _t('Gaawtagol', 'Téléchargements', 'التنزيلات');
  static String get downloadAll => _t('Aawtaade fof', 'Tout télécharger', 'تنزيل الكل');
  static String get deleteAll => _t('Momtu fof', 'Tout supprimer', 'حذف الكل');
  static String get deleteAllConfirm => _t('Aɗa yiɗi momtude cimooje gaawtaaɗe ɗe fof?',
      'Supprimer toutes les sourates téléchargées ?', 'هل تريد حذف جميع السور المنزّلة؟');
  static String get wifiOnly => _t('Aawtoro wiifii tan', 'Wi-Fi uniquement', 'عبر Wi-Fi فقط');
  static String get storageUsed => _t('Nokku kuutoraaɗo', 'Espace utilisé', 'المساحة المستخدمة');
  static String get waitingNetwork => _t('Ina sabbii weeyo', 'En attente de réseau', 'في انتظار الشبكة');
}
