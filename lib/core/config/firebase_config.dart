import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCjMt2wrlPJDXhl5HhhoNcji3XNWaG2aJE",
        authDomain: "quran-pulaar-dmwdqo.firebaseapp.com",
        projectId: "quran-pulaar-dmwdqo",
        storageBucket: "quran-pulaar-dmwdqo.appspot.com",
        messagingSenderId: "316874132271",
        appId: "1:316874132271:web:3aed6ac8ea4a0b05eaafda",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}
