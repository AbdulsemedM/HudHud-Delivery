package com.hudhud.userapp

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.location.Location
import android.location.LocationListener
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "custom_location"
    private val CONFIG_CHANNEL = "hudhud_delivery/config"
    private lateinit var locationManager: LocationManager
    private var currentLocation: Location? = null

    companion object {
        /** A last-known fix older than this is not used as "current location". */
        private const val MAX_CACHED_FIX_AGE_MS = 2 * 60 * 1000L
        /** Fixes within this radius (meters) are accepted immediately. */
        private const val GOOD_ACCURACY_M = 50f
        /** How long to wait for a live fix before using the best one seen. */
        private const val FRESH_FIX_TIMEOUT_MS = 12_000L

        private const val NOTIFICATION_CHANNEL_ID = "hudhud_delivery_channel_v4"
        private const val NOTIFICATION_CHANNEL_NAME = "HudHud Delivery"
        private val LEGACY_NOTIFICATION_CHANNEL_IDS = listOf(
            "hudhud_delivery_channel_v2",
            "hudhud_delivery_channel_v3",
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannelEarly()
    }

    private fun createNotificationChannelEarly() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        for (legacyId in LEGACY_NOTIFICATION_CHANNEL_IDS) {
            notificationManager.deleteNotificationChannel(legacyId)
        }

        val soundUri =
            Uri.parse("android.resource://${packageName}/raw/notification_sound")
        val audioAttributes =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        val channel =
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Notifications for HudHud Delivery"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
            }

        notificationManager.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isLocationServiceEnabled" -> {
                    val isEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                                   locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                    result.success(isEnabled)
                }
                "getCurrentLocation" -> {
                    getCurrentLocation(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONFIG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getGoogleMapsApiKey" -> {
                    result.success(BuildConfig.GOOGLE_MAPS_API_KEY ?: "")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ageMillis(location: Location): Long =
        (SystemClock.elapsedRealtimeNanos() - location.elapsedRealtimeNanos) / 1_000_000

    /** Most recent last-known fix across GPS and network providers. */
    private fun bestLastKnownLocation(): Location? {
        return listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .mapNotNull {
                try {
                    locationManager.getLastKnownLocation(it)
                } catch (_: SecurityException) {
                    null
                }
            }
            .minByOrNull { ageMillis(it) }
    }

    private fun toLocationMap(location: Location): Map<String, Any> = mapOf(
        "latitude" to location.latitude,
        "longitude" to location.longitude,
        "accuracy" to location.accuracy.toDouble(),
    )

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
            ).filter { locationManager.isProviderEnabled(it) }

            if (providers.isEmpty()) {
                result.error("NO_PROVIDER", "No location provider available", null)
                return
            }

            // A cached fix is only trusted when it is recent and accurate.
            // Previously any last-known fix was returned, which could be hours
            // old (wherever GPS was last used), so the map showed a wrong spot.
            val lastKnown = bestLastKnownLocation()
            if (lastKnown != null &&
                ageMillis(lastKnown) <= MAX_CACHED_FIX_AGE_MS &&
                lastKnown.hasAccuracy() &&
                lastKnown.accuracy <= GOOD_ACCURACY_M
            ) {
                currentLocation = lastKnown
                result.success(toLocationMap(lastKnown))
                return
            }

            // Ask GPS and network for a live fix at the same time. Answer with
            // the first accurate one, or the best one seen when time runs out.
            val handler = Handler(Looper.getMainLooper())
            var replied = false
            var best: Location? = null
            lateinit var listener: LocationListener
            lateinit var timeout: Runnable

            fun finish(location: Location?) {
                if (replied) return
                replied = true
                handler.removeCallbacks(timeout)
                locationManager.removeUpdates(listener)
                val answer = location ?: lastKnown
                if (answer != null) {
                    currentLocation = answer
                    result.success(toLocationMap(answer))
                } else {
                    result.error("location_timeout", "Timed out waiting for a location fix", null)
                }
            }

            listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (best == null || location.accuracy < best!!.accuracy) {
                        best = location
                    }
                    if (location.hasAccuracy() && location.accuracy <= GOOD_ACCURACY_M) {
                        finish(location)
                    }
                }

                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
                @Deprecated("Deprecated in API level 29")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            }
            timeout = Runnable { finish(best) }

            for (provider in providers) {
                locationManager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
            }
            handler.postDelayed(timeout, FRESH_FIX_TIMEOUT_MS)
        } catch (e: Exception) {
            result.error("LOCATION_ERROR", "Failed to get location: ${e.message}", null)
        }
    }
}
