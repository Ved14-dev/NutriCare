package com.example.nutricare_mvp

import android.content.Context
import androidx.multidex.MultiDex
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun attachBaseContext(base: Context) {
		super.attachBaseContext(base)
		// Ensure multidex is installed so apps with many methods can run on older devices/emulators
		MultiDex.install(this)
	}
}
