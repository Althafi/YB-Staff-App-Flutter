# YB Staff App

A Flutter mobile application for **YukBersihin** field staff. Staff use this app to manage their daily cleaning job schedule, track job status, submit final work reports, and receive real-time push notifications from the admin.

> **Portfolio project** — backend is a Laravel REST API deployed on [Railway](https://railway.app).

---

## Features

- **Authentication** — Login/logout with Laravel Sanctum token, persisted in secure storage. Auto session restore on app launch.
- **Daily Job Schedule** — Date navigator to browse assigned jobs by day. Pull-to-refresh support.
- **Job Detail** — Bottom sheet with full customer info, estimated items, pricing breakdown, photos, Google Maps link, and WhatsApp shortcut.
- **Job Status Flow** — Staff can progress a job through its lifecycle:
  `Ditugaskan → Sedang Dikerjakan → Menunggu Verifikasi → Invoice Dibuat`
- **Final Items Report** — Submit actual service items with optional discount (fixed amount) and down payment before job is finalized.
- **Profile Management** — Edit display name, phone number, and profile photo (camera or gallery).
- **Change Password** — Secure password update flow with current password verification.
- **Push Notifications** — FCM-powered notifications with local notification display for foreground messages. Tap-to-navigate to notification screen from both foreground and background states.
- **Notification Screen** — Unread badge count on home screen bell icon, mark-as-read per item or all at once.
- **Connectivity Observer** — In-app banner when device goes offline.
- **HTTP Inspector** — Alice inspector accessible from the profile menu for inspecting all API calls during development.

---

## Tech Stack

| Category | Library / Tool |
|---|---|
| Framework | Flutter (Dart 3.5+) |
| State Management | Riverpod 2.x (`Notifier`, `AsyncNotifierProvider.autoDispose.family`) |
| HTTP Client | `package:http` + custom `ApiClient` wrapper |
| Auth Storage | `flutter_secure_storage` |
| Push Notifications | Firebase Cloud Messaging + `flutter_local_notifications` |
| HTTP Inspector | Alice + alice_http |
| Fonts | Google Fonts — Plus Jakarta Sans |
| Localization | `flutter_localizations` (id_ID) |
| Image Picker | `image_picker` |
| Connectivity | `connectivity_plus` |
| Splash Screen | `flutter_native_splash` |
| Launcher Icon | `flutter_launcher_icons` |
| Backend | Laravel + Sanctum on Railway |

---

## Architecture

The app follows a **Clean Architecture-inspired** layered structure:

```
domain/         Pure business logic — entities & repository contracts
data/           Implementation — models, remote datasources, repository impls
presentation/   UI — Riverpod providers, screens, widgets
core/           Shared — ApiClient, theme, utils, FCM service, storage
```

**Key patterns:**
- `sealed class AuthState` (`AuthInitial` / `AuthLoading` / `AuthAuthenticated` / `AuthError`) drives the entire auth UI tree
- `Result<T>` (`Success<T>` / `Failure<T>`) used as the return type of all repository methods — no raw exceptions crossing layer boundaries
- `AsyncNotifierProvider.autoDispose.family<JobsNotifier, List<Job>, DateTime>` — each date has its own isolated provider that disposes when no longer watched
- `appNavigatorKey` (`GlobalKey<NavigatorState>`) enables navigation from FCM callbacks and the unauthorized handler outside the widget tree

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, routes, SplashRouter
├── firebase_options.dart
├── core/
│   ├── constants/api_constants.dart  # All endpoint paths
│   ├── network/
│   │   ├── api_client.dart           # HTTP wrapper (GET/POST/PUT/PATCH/DELETE/multipart)
│   │   ├── api_exception.dart
│   │   └── http_inspector.dart       # Alice instance
│   ├── services/fcm_service.dart     # FCM setup, token registration, notification display
│   ├── storage/token_storage.dart    # Secure token read/write
│   ├── theme/                        # AppColors, AppSpacing, AppTheme, AppTypography
│   ├── utils/                        # CurrencyFormatter, DateFormatter, Result, NavigatorKey
│   └── widgets/                      # AppToast, ConnectivityObserver
├── data/
│   ├── datasources/                  # Auth, Job, Notification remote datasources
│   ├── models/                       # UserModel, JobModel, JobItemModel, NotificationModel
│   └── repositories_impl/            # Auth, Job, Notification repository implementations
├── domain/
│   ├── entities/                     # User, Job, JobItem, ServiceItem, AppNotification
│   └── repositories/                 # Abstract repository contracts
└── presentation/
    ├── providers/                    # auth_provider, jobs_provider, notification_provider, catalog_provider
    ├── screens/
    │   ├── auth/login_screen.dart
    │   ├── home/home_screen.dart
    │   └── notification/notification_screen.dart
    └── widgets/
        ├── job_card.dart             # Home list card
        ├── job_detail_sheet.dart     # Full detail bottom sheet
        ├── final_items_sheet.dart    # Final report form (items, discount, DP)
        ├── profile_sheet.dart        # Edit profile photo + name + phone
        └── change_password_sheet.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Android SDK (min API 21) or Xcode 15+
- A Firebase project with Android & iOS apps configured
- The Laravel backend running (or use the staging URL below)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd yb_staff_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase**  
   Place your `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`. The `firebase_options.dart` is already committed — replace it with your own project config if needed.

4. **Run**
   ```bash
   flutter run
   ```

> The app points to the staging backend at `https://api-yukbersihin-staging.up.railway.app`. To change the base URL, edit `lib/core/constants/api_constants.dart`.

---

## API Overview

All endpoints require `Authorization: Bearer <token>` except login.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/login` | Staff login, returns `{ token, user }` |
| `GET` | `/api/auth/me` | Get authenticated user profile |
| `PUT` | `/api/profile` | Update name & phone |
| `POST` | `/api/auth/me/avatar` | Upload profile photo (multipart) |
| `POST` | `/api/profile/password` | Change password |
| `GET` | `/api/my-jobs?date=YYYY-MM-DD` | List jobs for a date |
| `POST` | `/api/my-jobs/{id}/start` | Start a job (assigned → in_progress) |
| `POST` | `/api/my-jobs/{id}/final-items` | Submit final items report |
| `GET` | `/api/staff/orders/{id}` | Full job detail |
| `GET` | `/api/notifications` | List notifications |
| `GET` | `/api/notifications/unread-count` | Unread badge count |
| `PATCH` | `/api/notifications/{id}/read` | Mark one as read |
| `PATCH` | `/api/notifications/read-all` | Mark all as read |
| `POST` | `/api/fcm-token` | Register FCM device token |
| `DELETE` | `/api/fcm-token` | Revoke FCM token on logout |
| `GET` | `/api/service-items?service_type=X` | Price catalog by service type |

---

## App Navigation

```
/ (SplashRouter)
 ├── token missing / invalid  →  /login
 └── session restored         →  /home
                                   └── /notifications
```

---

## Screenshots

> *Coming soon*

---

## License

This project is built as a personal portfolio piece and is not licensed for production use.
