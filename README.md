# Quraan Pulaar

A Flutter application that provides the Quran with Pulaar translation and audio recitation.

## Features

- Browse all Surahs of the Quran
- Read Pulaar translations
- Listen to audio recitations
- Bookmark favorite Surahs
- Beautiful and modern UI
- Firebase integration for real-time updates

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase account and project
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/kanaro92/quraan-pulaar-flutter-app.git
cd quraan-pulaar
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Copy `google-services.json` to `android/app/`
   - Copy the web configuration to `lib/core/config/firebase_options.dart` (use the template file as reference)

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── bindings/       # GetX bindings
│   ├── config/         # App configuration
│   ├── routes/         # App routes
│   ├── services/       # Services (Firebase, Audio, etc.)
│   └── theme/          # App theme
├── features/
│   ├── home/          # Home screen
│   └── surah/         # Surah-related screens
└── main.dart
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security

This project contains sensitive information that should not be committed to the repository:

- `google-services.json`
- `firebase_options.dart`
- Any API keys or secrets

Make sure to follow the installation instructions and keep these files secure.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The Noble Quran
- Flutter and Firebase teams
- All contributors and supporters
