package com.alera.payloadextraction

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Plays a bundled notification sound (res/raw) so the user can preview it in
 * the Reminder sound settings screen. Only one preview plays at a time.
 */
class NotificationSoundPreviewBridge(private val context: Context) {

    companion object {
        private const val TAG = "AleraSoundPreview"
        private const val CHANNEL = "com.alera.payloadextraction/notification_sounds"
    }

    private var player: MediaPlayer? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "preview" -> {
                        val name = call.argument<String>("resource")
                        result.success(if (name == null) false else preview(name))
                    }
                    "stop" -> {
                        stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun preview(name: String): Boolean {
        stop()
        val id = context.resources.getIdentifier(name, "raw", context.packageName)
        if (id == 0) {
            Log.w(TAG, "raw resource not found: $name")
            return false
        }
        return try {
            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            val afd = context.resources.openRawResourceFd(id)
            mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mp.setOnCompletionListener { stop() }
            mp.prepare()
            mp.start()
            player = mp
            true
        } catch (e: Exception) {
            Log.w(TAG, "preview failed for $name", e)
            stop()
            false
        }
    }

    fun stop() {
        player?.let {
            try {
                it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        player = null
    }
}
