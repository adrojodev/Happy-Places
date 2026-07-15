# Happy Places

Native iOS app, **live on the App Store** (bundle `rojo.happy-places-moments`). Users save meaningful places on a map with an icon, color, story, and photos. Internal project name is "Nice Places" — folder names, scheme, and test targets still use it.

## Critical rules

1. **NEVER RESET THE DB.** Real users have SwiftData stores synced through CloudKit. Never delete the store, never change the store URL, never make destructive schema changes.
2. **SwiftData models must stay CloudKit-compatible**: every attribute optional or with a default value; every relationship optional; no `.unique` constraints. Schema changes must be additive (lightweight migration). There is deliberately **no** VersionedSchema/SchemaMigrationPlan — don't add one without testing an upgrade from a store created by the shipping App Store build.
3. **New/removed Swift files must be registered in `Nice Places.xcodeproj/project.pbxproj`** (old-style project, objectVersion 56 — nothing is auto-discovered). Use the `xcode-add-file` skill. A file that compiles fine in isolation but is "not in scope" everywhere usually means it isn't registered.
4. **Release checklist — CloudKit schema promotion**: any new @Model (e.g. `PlacePhoto`) only exists in the CloudKit *Development* environment until promoted. Before shipping a release that adds a record type: run a debug build, save data touching the new model, open CloudKit Console → container `iCloud.rojo.happy-places` → "Deploy Schema Changes…" to Production, then verify sync on TestFlight. Skipping this makes sync silently fail for all users.
5. Usage-description strings live in **`INFOPLIST_KEY_*` build settings** in project.pbxproj (`GENERATE_INFOPLIST_FILE = YES`) merged with `Nice-Places-Info.plist`. Camera + photo-library strings are in the plist; location string is a build setting.

## Build / test / run

```sh
# Build
xcodebuild -project "Nice Places.xcodeproj" -scheme "Happy Places" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Unit + UI tests
xcodebuild -project "Nice Places.xcodeproj" -scheme "Happy Places" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

- Scheme: `Happy Places` (the only one). Module name for `@testable import`: `Happy_Places`.
- Deployment target iOS 17. Simulators available: iPhone 17 / 17 Pro / 17 Pro Max / 17e / Air.
- No external dependencies — 100% Apple frameworks (SwiftUI, SwiftData, CloudKit, MapKit, CoreLocation, PhotosUI).

## Architecture

```
Nice Places/
├── HappyPlacesApp.swift        # Entry; ModelContainer (CloudKit, local-only fallback)
├── HappyPlacesView.swift       # Root TabView: List + Map tabs
├── Models/PlacesDataModel.swift# @Model Place and PlacePhoto (photos: cascade, external storage)
├── Data/Icons.swift            # SF Symbol icon list + PlaceColor enum
├── Components/                 # Reusable views (sheets, pickers, badges, list rows)
├── Views/                      # Screens (list, maps, place detail, new place)
├── Utils/                      # CloudKitSyncMonitor, PhotoProcessing (GPS/resize helpers)
└── Location/                   # Location services
```

- State: plain SwiftUI (`@State`/`@Binding`/`@Environment`, `@Observable` classes). Data via `@Query` + `modelContext`.
- `CloudKitSyncMonitor` is injected from the app root via `.environment(...)`; views read it with `@Environment(CloudKitSyncMonitor.self)`. Previews that render such views must inject both a `ModelContainer` and a monitor.
- Photos are stored downscaled (≤2048px JPEG) in `PlacePhoto.imageData` (`.externalStorage`). Use `PhotoProcessing` helpers for resizing/GPS extraction — don't reimplement.
- `PhotosPicker`/`.photosPicker` calls must pass `photoLibrary: .shared()` or `itemIdentifier` is nil and PHAsset GPS lookup breaks.

## Conventions

- Standard Swift/SwiftUI style, 4-space indent, no linters configured.
- Prefer existing shared components/extensions over inline duplicates (icon badge, place color, open-in-Maps, date formatting).
- User-facing strings are English, casual tone ("Happy place", "Let's go").
- Commit style: short imperative subject lines (see git log).

## Skills

- `build` — build/test invocations and common failure causes.
- `xcode-add-file` — exact procedure to register new files in project.pbxproj.
- `verify` — end-to-end verification in the simulator (includes seeding GPS-tagged photos).
