package app.luma.convert

import android.content.Context
import androidx.core.content.edit
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "app.luma.convert/storage"
    private val preferencesName = "luma_convert_state"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                when (call.method) {
                    "read" -> result.success(preferences.getString("state", null))
                    "write" -> {
                        val state = call.arguments as? String
                        if (state == null) {
                            result.error("INVALID_STATE", "Expected JSON text", null)
                        } else {
                            preferences.edit { putString("state", state) }
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("STORAGE_UNAVAILABLE", error.message, null)
            }
        }
    }
}
