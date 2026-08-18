# Firebase Cloud Messaging (FCM) setup — OXALIA

Push notifications fire when an exam analysis completes or fails.

## 1. Firebase Console

1. Create a project at https://console.firebase.google.com
2. Add an **Android** app with package name `com.example.oxalia_front`
   (change it later to your real applicationId)
3. Download `google-services.json` → place it in:
   `oxalia_front/android/app/google-services.json`
4. (Optional iOS) Add an iOS app and put `GoogleService-Info.plist` in
   `oxalia_front/ios/Runner/`
5. Project settings → **Service accounts** → Generate new private key
   → save the JSON somewhere safe (not in git), e.g.
   `oxalia_back/secrets/firebase-adminsdk.json`

## 2. Flutter

```bash
cd oxalia_front
flutter pub get
# Recommended (generates lib/firebase_options.dart):
dart pub global activate flutterfire_cli
flutterfire configure
```

If you generate `firebase_options.dart`, update
`PushNotificationService.initialize()` to:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Until then, Android can init from `google-services.json` alone.

## 3. Backend

```bash
cd oxalia_back
pip install -r requirements.txt
alembic upgrade head
```

Add to `oxalia_back/.env`:

```env
FIREBASE_CREDENTIALS_PATH=secrets/firebase-adminsdk.json
```

Restart the API. If the path is empty/missing, the API still runs; push is skipped.

## 4. Verify

1. Log in on the phone → grant notification permission
2. Upload an exam (or wait for stub inference to finish)
3. You should get: **Analysis ready** / **Analysis failed**
4. Tap the notification → opens `/exams/{id}`

## Notes

- Notification text uses the patient name only (no clinical findings)
- Stale FCM tokens are deleted automatically after send failures
- `google-services.json` and the Admin SDK JSON must stay out of git
