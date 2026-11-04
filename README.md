# YB Staff App

A Flutter mobile application for **YukBersihin** field staff. Staff use this app to manage their daily cleaning job schedule, track job status, submit final work reports, and receive real-time push notifications from the admin.

> **Portfolio project** — backend is a Laravel REST API deployed on [Railway](https://railway.app).

---

## Features

- **Authentication** — Login/logout with Laravel Sanctum token, persisted in secure storage. Auto session restore on app launch.
- **Daily Job Schedule** — Date navigator to browse assigned jobs by day. Pull-to-refresh support and skeleton loading placeholders.
- **Job Detail** — Bottom sheet with full customer info, on-site contact (person at the location), estimated items, pricing breakdown, invoice summary, photos, region/power badge, notes, Google Maps link, and WhatsApp shortcut.
- **Job Status Flow** — Staff can progress a job through its lifecycle:
  `Ditugaskan → Sedang Dikerjakan → Menunggu Verifikasi → Invoice Dibuat → Selesai` (or `Dibatalkan`)
- **Final Items Report** — Submit actual service items with optional discount (fixed amount) and down payment before job is finalized. Report can be edited again while the job is still editable.
- **Hourly Jobs** — Hourly orders show planned duration, cleaner count, and estimated total. Staff submit (or update) the actual duration, cleaner count, and notes via the hourly report sheet.
- **Confirmation Dialogs** — Sensitive actions (e.g. starting a job, submitting a report) ask for confirmation first.
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
| Localization | `flutter_localizations` + `intl` (id_ID) |
| Image Picker | `image_picker` |
| Connectivity | `connectivity_plus` |
| External Links | `url_launcher` (Maps, WhatsApp, phone) |
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
- `appLifecycleProvider` exposes the app lifecycle state (foreground/background) to providers
- `Job` aggregates optional sub-entities (`HourlyDetails`, `HourlyReport`, `InvoiceSummary`) so hourly and invoice data stay isolated from the base job fields

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, routes, SplashRouter
├── firebase_options.dart             # Gitignored — copy from firebase_options.example.dart
├── firebase_options.example.dart
├── core/
│   ├── config/                       # env.dart (gitignored) & env.example.dart — base URL
│   ├── constants/                    # api_constants.dart (endpoint paths), app_strings.dart
│   ├── network/
│   │   ├── api_client.dart           # HTTP wrapper (GET/POST/PUT/PATCH/DELETE/multipart)
│   │   ├── api_exception.dart
│   │   └── http_inspector.dart       # Alice instance
│   ├── providers/app_lifecycle_provider.dart
│   ├── services/fcm_service.dart     # FCM setup, token registration, notification display
│   ├── storage/token_storage.dart    # Secure token read/write
│   ├── theme/                        # AppColors, AppSpacing, AppTheme, AppTypography
│   ├── utils/                        # CurrencyFormatter, DateFormatter, ItemFormatter, Result, NavigatorKey
│   └── widgets/                      # AppToast, ConnectivityObserver
├── data/
│   ├── datasources/                  # Auth, Job, Notification remote datasources
│   ├── mock/                         # Mock job repository for local UI testing
│   ├── models/                       # User, Job, JobItem, HourlyDetails, HourlyReport, InvoiceSummary, ServiceItem, Notification models
│   └── repositories_impl/            # Auth, Job, Notification repository implementations
├── domain/
│   ├── entities/                     # User, Job, JobItem, HourlyDetails, HourlyReport, InvoiceSummary, ServiceItem, AppNotification
│   └── repositories/                 # Abstract repository contracts
└── presentation/
    ├── providers/                    # auth_provider, jobs_provider, notification_provider, catalog_provider
    ├── screens/
    │   ├── auth/login_screen.dart
    │   ├── home/home_screen.dart
    │   └── notification/notification_screen.dart
    └── widgets/
        ├── job_card.dart             # Home list card
        ├── job_card_skeleton.dart    # Loading placeholder
        ├── empty_jobs.dart           # Empty state
        ├── job_detail_sheet.dart     # Full detail bottom sheet
        ├── final_items_sheet.dart    # Final report form (items, discount, DP)
        ├── hourly_report_sheet.dart  # Hourly report form (actual duration, cleaners, notes)
        ├── confirm_dialog.dart       # Confirmation dialog for sensitive actions
        ├── profile_sheet.dart        # Edit profile photo + name + phone
        ├── change_password_sheet.dart
        ├── app_text_field.dart       # Shared text input
        └── primary_button.dart       # Shared primary button
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

3. **Environment config**  
   Copy `lib/core/config/env.example.dart` to `lib/core/config/env.dart` and set `baseUrl`. `env.dart` is gitignored and must not be committed.

4. **Firebase**  
   Place your `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`. Copy `lib/firebase_options.example.dart` to `lib/firebase_options.dart` and replace it with your own project config (gitignored).

5. **Run**
   ```bash
   flutter run
   ```

> The base URL is read from `Env.baseUrl` in `lib/core/config/env.dart` (e.g. the staging backend at `https://api-yukbersihin-staging.up.railway.app`). Endpoint paths live in `lib/core/constants/api_constants.dart`.

---

## API Overview

All endpoints require `Authorization: Bearer <token>` except login.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/login` | Staff login, returns `{ token, user }` |
| `POST` | `/api/auth/logout` | Invalidate current Sanctum token |
| `GET` | `/api/auth/me` | Get authenticated user profile |
| `PUT` | `/api/profile` | Update name & phone |
| `POST` | `/api/profile/avatar` | Upload profile photo (multipart) |
| `POST` | `/api/profile/password` | Change password |
| `GET` | `/api/my-jobs?date=YYYY-MM-DD` | List jobs for a date |
| `POST` | `/api/my-jobs/{id}/start` | Start a job (assigned → in_progress) |
| `POST` | `/api/my-jobs/{id}/final-items` | Submit final items report |
| `POST` / `PUT` | `/api/my-jobs/{id}/hourly-report` | Submit / update hourly report (actual duration, cleaner count) |
| `POST` | `/api/my-jobs/{id}/photos` | Upload job item photo (multipart) |
| `DELETE` | `/api/my-jobs/{id}/photos/{photoId}` | Delete an uploaded job photo |
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
