package auto.grom.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // AG_PUSHSTYLE1: канал уведомлений со звуком и всплывающим окном
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel("ag_main", "Уведомления AG Service", NotificationManager.IMPORTANCE_HIGH)
            ch.description = "Записи, чат, бонусы, фото приёмки"
            ch.enableVibration(true)
            ch.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION), AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }
}
