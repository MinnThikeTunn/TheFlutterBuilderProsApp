# Native Setup: Biometrics & Secure Storage

The `rewards_sdk` relies on hardware-backed secure storage and local biometric authentication.

## Android Configuration

### 1. Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

### 2. MainActivity (`android/app/src/main/kotlin/.../MainActivity.kt`)
Ensure `MainActivity` extends `FlutterFragmentActivity` for BiometricPrompt support:
```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

### 3. KeyStore Options
The SDK automatically utilizes Android KeyStore with AES-256-GCM hardware backing when available.

---

## iOS Configuration

### 1. Info.plist (`ios/Runner/Info.plist`)
Add the Face ID usage description string:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Authenticate to approve secure Rewards transfers and access your keys.</string>
```

### 2. Keychain Access Groups
Keypairs and seed secrets are saved with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
