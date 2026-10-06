# Wander

A travel destination app. Flutter front end (phone, tablet, web, desktop) and a FastAPI + SQLite back end.

```
wander/
  backend/   FastAPI API, SQLite DB, tests
  app/       Flutter app (lib/ + pubspec.yaml)
```

## 1. Start the API

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Check it at http://localhost:8000/docs. The database file is created on first start.
Run the tests with `pytest`.

## 2. Start the app

```bash
cd app
flutter create . --project-name wander --org com.example
flutter pub get
flutter run -d chrome
```

`flutter create .` only adds the platform folders (android, ios, web...) and keeps the `lib/` and `pubspec.yaml` from this project. Delete the generated `test/widget_test.dart` (it points at a demo app that does not exist here); `test/wander_test.dart` replaces it.

Where the API lives depends on where the app runs:

| Running on | API address |
|---|---|
| Chrome, desktop, iOS simulator | `http://localhost:8000` (default) |
| Android emulator | `http://10.0.2.2:8000` (default) |
| Real phone on your Wi-Fi | `flutter run --dart-define=API_URL=http://<your-pc-ip>:8000` |
| Deployed server | `flutter run --dart-define=API_URL=https://your-api.example.com` |

### Android needs two manifest lines
In `android/app/src/main/AndroidManifest.xml`, above `<application`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
and inside the `<application` tag add `android:usesCleartextTraffic="true"` (only needed while you talk to plain `http://` during development).

## What it does
- Explore: swipeable carousel on phones, hover-colour grid on wide screens.
- Search and mood filters.
- Detail: trip length slider with live cost, pack list, Save / Update / Remove.
- Trips tab: your saved trips from the server, with pack progress.
- Each install gets a random id, so trips are stored per device with no login.

## API
| Method | Path | |
|---|---|---|
| GET | `/api/destinations?mood=&q=` | list and filter |
| GET | `/api/destinations/{id}` | one place |
| GET | `/api/destinations/{id}/estimate?days=` | cost estimate |
| GET | `/api/trips?client_id=` | saved trips |
| PUT | `/api/trips` | save or update a trip |
| DELETE | `/api/trips/{id}?client_id=` | remove a trip |
