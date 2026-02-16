# Firebase Setup - Remaining Manual Steps

## What's Already Done (via CLI)

| Item | Status | Details |
|------|--------|---------|
| Firebase project created | Done | `mialarm-geofence-demo` |
| Android app registered | Done | `com.finmon.mialarm_geofence` |
| google-services.json | Done | Downloaded and placed in `android/app/` |
| Firestore database | Done | `(default)` in `nam5` (US multi-region) |
| Firestore security rules | Done | Deployed - auth-required for all collections |
| Firestore composite index | Done | `events` collection: panelId + timestamp DESC |
| Cloud Messaging API | Done | FCM enabled |
| Maps SDK for Android | Done | Enabled + API key in AndroidManifest.xml |
| Maps JavaScript API | Done | Enabled |
| Identity Toolkit API | Done | Enabled (underlying Auth API) |

## What You Need to Do

### 1. Enable Firebase Authentication (Email/Password)

The Firebase CLI can't enable auth sign-in providers. You need to do this in the console.

1. Go to: https://console.firebase.google.com/project/mialarm-geofence-demo/authentication
2. Click **"Get started"**
3. Under **Sign-in method** tab, click **Email/Password**
4. Toggle **Enable** to on
5. Click **Save**

**Why:** The app uses `firebase_auth` for login/register. Without this, `signInWithEmailAndPassword` will throw `OPERATION_NOT_ALLOWED`.

### 2. Create a Test User (Optional)

You can do this via the console or just register through the app itself.

**Via console:**
1. Go to: https://console.firebase.google.com/project/mialarm-geofence-demo/authentication/users
2. Click **Add user**
3. Enter email + password

**Via app:** Just use the Register screen in the app.

### 3. Seed Demo Data

After logging in, the app needs data to display. The `SeedService` class can populate this. You have two options:

**Option A: Add a seed button (quickest)**
I can add a temporary "Seed Data" button to the dashboard that calls `SeedService().seedDemoData(userId: currentUser.uid)`.

**Option B: Use Firestore console**
1. Go to: https://console.firebase.google.com/project/mialarm-geofence-demo/firestore
2. Manually create documents following the schema in `lib/models/`

### 4. Google Maps API Key Restrictions (Recommended)

The Maps API key is currently unrestricted. For production:

1. Go to: https://console.cloud.google.com/apis/credentials?project=mialarm-geofence-demo
2. Click the **Android key (auto created by Firebase)**
3. Under **Application restrictions**, select **Android apps**
4. Add your app's SHA-1 fingerprint:
   ```bash
   # Get debug SHA-1
   cd android && ./gradlew signingReport | grep SHA1
   ```
5. Under **API restrictions**, restrict to only:
   - Maps SDK for Android
   - Maps JavaScript API

### 5. SHA-1 Fingerprint for Firebase (If Google Sign-In needed later)

Not needed now (only using email/password), but if you add Google Sign-In:

1. Get SHA-1: `cd android && ./gradlew signingReport`
2. Go to: https://console.firebase.google.com/project/mialarm-geofence-demo/settings/general
3. Scroll to your Android app
4. Click **Add fingerprint**
5. Paste the SHA-1

### 6. Billing (Optional - Not Needed Yet)

The current setup uses only free-tier services:
- Firestore: 1GB storage, 50K reads/day, 20K writes/day
- Auth: Unlimited email/password users
- FCM: Free unlimited
- Maps: $200/month free credit

You only need billing if you later want:
- Cloud Functions (for geofence auto-arm logic)
- Identity Platform (advanced auth features)
- Firestore beyond free tier

## Quick Verification Checklist

After completing the manual steps, verify:

- [ ] Firebase Console > Authentication > Sign-in method shows Email/Password enabled
- [ ] Can register a new user through the app
- [ ] Can log in with the created user
- [ ] Firestore Console shows collections being created (after seed or first use)

## Console Links

| Resource | URL |
|----------|-----|
| Project Overview | https://console.firebase.google.com/project/mialarm-geofence-demo/overview |
| Authentication | https://console.firebase.google.com/project/mialarm-geofence-demo/authentication |
| Firestore | https://console.firebase.google.com/project/mialarm-geofence-demo/firestore |
| Cloud Messaging | https://console.firebase.google.com/project/mialarm-geofence-demo/messaging |
| API Credentials | https://console.cloud.google.com/apis/credentials?project=mialarm-geofence-demo |
