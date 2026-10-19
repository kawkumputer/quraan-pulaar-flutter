/// Sourates accessibles sans activation (présentes dans assets/data/surahs.json).
const Set<int> kFreeSurahs = {1, 112, 113, 114};

/// À incrémenter quand le format des boxes Hive change : le cache est alors vidé une fois.
const int kCacheSchemaVersion = 2;

/// Durée après laquelle le contenu en cache est rafraîchi depuis Firestore.
const Duration kContentRefreshInterval = Duration(hours: 24);

const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=mr.quran_pulaar';
const String kAppStoreUrl = 'https://apps.apple.com/app/id6742410170';

/// Ordre d'affichage des sourates.
enum SurahOrder { descending, ascending }
