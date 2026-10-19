package mr.quran_pulaar

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // ANDROID_ID : identifiant propre à l'appareil (et à la clé de signature),
        // stable aux réinstallations et mises à jour Android.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mr.quran_pulaar/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "getAndroidId") {
                    result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                } else {
                    result.notImplemented()
                }
            }
    }
}
