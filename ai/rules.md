# Colosseum Client — AI Development Rules & Architecture Guidelines

> **Project:** Colosseum Audio Tour Guide (Mobile Client)  
> **Platform:** Flutter (Dart) & GetX (GetX Pattern)  
> **Target Environment:** Android & iOS (Offline-First, Sensor-Fused Indoor Navigation & Audio Tour)  
> **Location:** Rome, Italy (Colosseum Pilot: Ground/Arena, First Level, Second Level, Hypogeum)

---

## 1. Core Architectural Principles

1. **GetX Pattern & Clean Architecture Separation:**
   - **Views (`lib/app/modules/<feature>/views/`):** Pure UI layer (`GetView<Controller>` or `GetWidget<Controller>`). Keep widgets stateless whenever possible. Do not put business logic or direct API/storage calls in Views.
   - **Controllers (`lib/app/modules/<feature>/controllers/`):** Manage feature state and user actions. Derive from `GetxController`. Use reactive variables (`.obs`) and lightweight worker triggers (`ever`, `debounce`, `interval`). Always clean up streams, sensor listeners, and timers in `onClose()`.
   - **Bindings (`lib/app/modules/<feature>/bindings/`):** Manage dependency injection using `Get.lazyPut<T>()` or `Get.put<T>()`. Every page/route must have a corresponding binding.
   - **Data Layer (`lib/app/data/`):**
     - `models/`: Immutable Dart data classes with `fromJson`/`toJson` serializers and `copyWith` methods.
     - `providers/`: Network (HTTP/REST) and local database/cache data sources.
     - `repositories/`: Repository pattern isolating business logic from raw data sources.
     - `services/`: Long-lived singleton services (`GetxService`) for Sensors, Audio Player, Offline Sync, and Location.
   - **Routes (`lib/app/routes/`):** Centralized route constants (`app_routes.dart`) and page mapping (`app_pages.dart`).

2. **Offline-First Paradigm:**
   - The entire tour experience (maps, floor datasets, POI metadata, narration audio files) must function flawlessly with **zero internet connection** once downloaded.
   - Cache state locally (SQLite/Drift/GetStorage) with versioned metadata for incremental updates.
   - Gracefully handle offline states without blocking user interactions.

3. **Sensor-Fusion & Positioning Safety:**
   - Real-time sensor streams (Barometer, Accelerometer, Gyroscope, Magnetometer, GPS) consume high CPU and battery if unmanaged.
   - Sample rates must be throttled and paused when the app is backgrounded or when high-frequency tracking is unnecessary.
   - Isolate raw sensor processing into dedicated background/service workers to avoid dropping UI frames (maintain 60+ FPS).

---

## 2. Project Directory Structure

Follow the standard GetX Pattern structure strictly:

```
lib/
├── app/
│   ├── core/                        # Core utilities, themes, constants, extensions
│   │   ├── constants/               # Asset paths, API endpoints, floor IDs, sensor constants
│   │   ├── theme/                   # Centralized theme tokens (equivalent to index.css)
│   │   │   ├── app_colors.dart      # Semantic color palette (Light tokens)
│   │   │   ├── app_radius.dart      # Border radius & geometry tokens
│   │   │   ├── app_theme.dart       # Light ThemeData configuration
│   │   │   └── theme_extensions.dart# context.colors & Get.colors helper extensions
│   │   ├── utils/                   # Helpers, formatters, math/geodesic calculations
│   │   └── values/                  # Strings, dimensions, borders
│   ├── data/
│   │   ├── models/                  # FloorModel, PoiModel, TourModel, TicketModel, SensorDataModel
│   │   ├── providers/               # ApiProvider, DatabaseProvider, LocalStorage
│   │   ├── repositories/            # TourRepository, TicketRepository, SensorRepository
│   │   └── services/                # SensorFusionService, AudioPlayerService, LocationService
│   ├── modules/                     # Feature modules (View + Controller + Binding)
│   │   ├── home/                    # Landing / Overview module
│   │   ├── ticket/                  # Ticket & Token entry / validation module
│   │   ├── tour_overview/           # Tour download, language selection, preparation
│   │   ├── active_tour/             # Floor-aware map, POI trigger, guide player
│   │   ├── audio_player/            # Narration player controls & mini-player widget
│   │   └── diagnostics/             # Live sensor dashboard & calibration overlay (Phase 1 PoC)
│   └── routes/
│       ├── app_pages.dart           # Route definitions with bindings
│       └── app_routes.dart          # Route string constants
└── main.dart                        # App entry point (GetMaterialApp)
```

---

## 3. Theme & Styling System (Single Source of Truth)

Just like `index.css` in Next.js / Tailwind CSS projects, all design tokens are defined in **one central location**:

### A. Color & Radius Tokens Definition
- **File:** [`lib/app/core/theme/app_colors.dart`](file:///mnt/503ADFEC3ADFCD5A/code/Android/Colosseum/project/ColosseumClient/lib/app/core/theme/app_colors.dart)
  - `AppColors.light` corresponds to the `:root` light mode palette (Roman historical theme).
- **File:** [`lib/app/core/theme/app_radius.dart`](file:///mnt/503ADFEC3ADFCD5A/code/Android/Colosseum/project/ColosseumClient/lib/app/core/theme/app_radius.dart)
  - `AppRadius.sm` (6px), `AppRadius.md` (8px), `AppRadius.lg` (10px), `AppRadius.xl` (14px).

### B. Usage Rules in Widgets
1. **Never Hardcode Colors:**
   - ❌ **Forbidden:** `color: Colors.red`, `color: Color(0xFFDD1110)`, `color: Colors.white`
   - ✅ **Mandatory:** `color: context.colors.primary`, `color: context.colors.background`, `color: context.colors.card`
2. **Access Methods:**
   - Inside any widget build method: `context.colors.<token>`.
   - Text styling: `context.textTheme.<style>`.
   - In controllers/services without context: `Get.colors.<token>`.
3. **Theme Customization:**
   - To update the app's entire look & feel, only change the color definitions in [`app_colors.dart`](file:///mnt/503ADFEC3ADFCD5A/code/Android/Colosseum/project/ColosseumClient/lib/app/core/theme/app_colors.dart). All views and components will reflect the change automatically.

---

## 4. Flutter & Dart Coding Standards

1. **Type Safety & Linting:**
   - Enforce strict null safety. Avoid `dynamic` unless interacting with raw JSON, and validate/type-cast immediately.
   - Mark constructors as `const` wherever feasible to optimize widget rebuilds.
   - Use `final` for variables that do not mutate.
   - Avoid `!` (bang operator) assertions; use safe unwrapping (`?.`, `??`, `if-case`, or early guard clauses).

2. **Reactive State Management with GetX:**
   - Prefer fine-grained `Obx(() => ...)` wrappers around specific widgets rather than rebuilding entire screen trees.
   - Avoid creating new reactive objects inside `build()` methods.
   - Never call `setState()` in GetX-managed views.

3. **Dependency Injection:**
   - Use `Get.find<T>()` only when the dependency is guaranteed to be in memory.
   - Bind dependencies via `Bindings` in `GetPage`.
   - For global infrastructure services (Sensors, Audio, Storage), extend `GetxService` and initialize them in `main.dart` with `await Get.putAsync(() => Service().init())`.

4. **Error Handling & Logging:**
   - Never swallow errors silently. Catch specific exceptions (`TimeoutException`, `SocketException`, `SensorException`).
   - Use structured logging with diagnostic tags (e.g., `[SensorFusion]`, `[AudioPlayer]`, `[SyncService]`).
   - Prepare crash and sensor telemetry integration (Firebase Crashlytics / Sentry).

---

## 5. Specific Domain Rules

### A. Ticket & Token Validation
- Validate ticket tokens against the server when online; store token state and validity flags locally for offline verification.
- Enforce clean input formatting for token entries (trim spaces, uppercase canonicalization).

### B. Floor Detection & Sensor Fusion
- **Barometer (Altitude Delta):** Compute relative pressure changes ($\approx 12\text{ Pa/m}$) against calibrated ground/entrance baseline.
- **Pedestrian Dead Reckoning (PDR):** Combine step counting (accelerometer) + heading (fused magnetometer + gyroscope).
- **POI Proximity Triggering:** Calculate Euclidean / Geodesic distance on the active floor. Enforce a minimum cooldown/hysteresis window to avoid repeated trigger spam for the same POI.
- **Fallback Behavior:** Gracefully fallback to manual floor selection or GPS-only mode when hardware sensors (e.g., barometer) are missing on budget devices.

### C. Audio Narration & Guide Player
- Narration must support both **automated hands-free triggering** (via POI proximity) and **manual override** (play, pause, seek, replay).
- Ensure background audio playback capability and audio focus handling when earphones are disconnected or phone calls are received.

### D. Diagnostics Overlay (Phase 1 PoC)
- Maintain an in-app diagnostic HUD/overlay displaying:
  - Live sensor outputs (Pressure, Accelerometer, Gyro, Compass heading).
  - Detected Floor vs Ground Baseline.
  - Estimated Position vs Target POI proximity.
  - Active audio narration state.

---

## 6. Verification & Testing Rules

1. **Before Completing Any Task:**
   - Run `flutter analyze` to ensure 0 errors and 0 warnings.
   - Run `flutter test` to ensure all unit and widget tests pass.
2. **Unit Tests:**
   - Write unit tests for all Controllers, Services, and Repositories under `test/unit/`.
   - Mock external sensor streams and HTTP client responses.
3. **Widget Tests:**
   - Test UI components under `test/widget/` using `tester.pumpWidget(GetMaterialApp(...))`.

---

## 7. Build & Distribution Rules (Universal Release Artifacts)

1. **Mandatory Universal (Fat) Build Rule:**
   - **Always generate Universal (Fat) APKs** (`flutter build apk --release --no-tree-shake-icons`).
   - ❌ **Forbidden:** Never use `--split-per-abi` for direct tourist sideloading or on-site delivery.
   - **Rationale:** A split APK (e.g. `arm64-v8a` only) immediately crashes on 32-bit (`armeabi-v7a`), x86, or emulator/rental devices with fatal `INSTALL_FAILED_NO_MATCHING_ABIS`. Universal APKs bundle all ABIs to ensure 100% device compatibility across varied visitor hardware.

