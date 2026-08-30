# Custom FCM notification sound (Flutter)

Use **native OS notification sound**, not Dart/`just_audio`. Dart playback only works in the foreground and is unreliable (or silent) when the app is backgrounded or killed.

## 1. Sound files (native, not Flutter assets)

| Platform | Path | Name rules |
|----------|------|------------|
| Android | `android/app/src/main/res/raw/notification_sound.mp3` | lowercase, no hyphens; resource name is `notification_sound` (no extension) |
| iOS | `ios/Runner/notification_sound.caf` | add to the **Runner** Xcode target (Copy Bundle Resources) |

Convert from a source clip (≤30s). Mono is cleaner on the notification stream:

```bash
ffmpeg -i your_clip.mp3 -ac 1 -ar 44100 android/app/src/main/res/raw/notification_sound.mp3
ffmpeg -i your_clip.mp3 -ac 1 -ar 44100 ios/Runner/notification_sound.caf
```

On macOS, CAF can also be made with `afconvert -f caff -d ima4 source.mp3 ios/Runner/notification_sound.caf`.

Do **not** put the sound only in `assets/` for FCM. Flutter assets are not used by the OS when it displays a push.

## 2. Android channel + manifest

Android channel sound is **immutable** after first create. If you ever shipped `playSound: false`, bump the channel id (e.g. `_v3`).

Create the channel in Flutter (`flutter_local_notifications`):

```dart
const channelId = 'your_app_channel_v3';

const channel = AndroidNotificationChannel(
  channelId,
  'Your App',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notification_sound'),
);
```

Match it in `AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="your_app_channel_v3" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_sound"
    android:resource="@raw/notification_sound" />
```

Local notifications must use the **same** `channelId` and `sound`.

## 3. iOS local notifications

```dart
const DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  sound: 'notification_sound.caf',
);
```

Add the `.caf` to the Xcode Runner target or iOS will fall back to the default sound.

## 4. App states (pick one sound path, not two)

| App state | Who plays the sound |
|-----------|---------------------|
| Foreground | App shows a **local** notification with native sound |
| Background / killed + `notification` payload | **OS** plays sound from the FCM/APNs payload |
| Background + data-only (no `notification` block) | Background handler shows a local notification with native sound |

Foreground: disable FCM system sound (and usually the system banner) so you do not get **double** playback:

```dart
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  alert: false,
  badge: true,
  sound: false,
);
```

Background handler: if `message.notification != null`, return (OS already showed it). If data-only, `show()` a local notification with the same channel/sound.

## 5. Backend payload (required for background/killed)

Do **not** send `"sound": "default"`.

```json
{
  "notification": { "title": "...", "body": "..." },
  "android": {
    "notification": {
      "channel_id": "your_app_channel_v3",
      "sound": "notification_sound"
    }
  },
  "apns": {
    "payload": {
      "aps": { "sound": "notification_sound.caf" }
    }
  }
}
```

`channel_id` must match the Flutter channel. iOS filename must match the bundled file (case-sensitive).

## 6. Checklist on a real device

- Foreground: one banner, custom sound once
- Background / killed with notification payload: OS uses custom sound
- Data-only in background: local notification + custom sound
- Existing Android users: new channel id (or uninstall) after changing sound settings
