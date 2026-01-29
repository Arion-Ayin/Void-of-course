package com.example.lioluna

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Edge-to-Edge 모드 활성화 (Android 15+에서 권장)
        // Flutter에서 시스템 UI 인셋을 직접 처리하도록 설정
        WindowCompat.setDecorFitsSystemWindows(window, false)

        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the NativeAdFactory.
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "listTile", NativeAdFactory(context))
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)

        // Unregister the NativeAdFactory to prevent memory leaks.
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
    }
}