/// Sourates accessibles sans activation (présentes dans assets/data/surahs.json).
const Set<int> kFreeSurahs = {1, 112, 113, 114};

/// Intervalle minimal entre deux synchronisations du texte au retour dans l'app
/// (chaque synchro ne télécharge que les versets corrigés).
const Duration kContentRefreshInterval = Duration(hours: 1);

/// WhatsApp d'Abou Sy (ventes, changement de téléphone).
const String kContactWhatsapp = '221773091782';

const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=mr.quran_pulaar';
const String kAppStoreUrl = 'https://apps.apple.com/app/id6742410170';

/// Ordre d'affichage des sourates.
enum SurahOrder { descending, ascending }
