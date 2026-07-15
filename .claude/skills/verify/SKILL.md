---
name: verify
description: Verify a Happy Places change end-to-end in the iOS simulator — build, test, install, launch, and exercise the affected flow (including seeding GPS-tagged photos).
---

# Verifying changes end-to-end

## 1. Build + tests

Follow the `build` skill. Both must be green before driving the UI.

**Gotcha:** several simulators share the name "iPhone 17 Pro" (one per runtime). Seed/grant/install commands target the *booted* device, but `xcodebuild -destination name=...` may pick a different one. Always pin UI-test runs with `-destination 'id=<UDID>'` (find it via `xcrun simctl list devices | grep Booted`) and pass `-parallel-testing-enabled NO` so tests run on the seeded device instead of a fresh clone.

## 2. Install & launch in the simulator

```sh
SIM="iPhone 17 Pro"
xcrun simctl boot "$SIM" 2>/dev/null; open -a Simulator
APP=$(find ~/Library/Developer/Xcode/DerivedData/Nice_Places-*/Build/Products/Debug-iphonesimulator -maxdepth 1 -name "Happy Places.app" | head -1)
xcrun simctl install "$SIM" "$APP"
xcrun simctl launch "$SIM" rojo.happy-places-moments
```

Screenshots: `xcrun simctl io "$SIM" screenshot /tmp/shot.png` (then Read the png).

## 3. Simulate a location

```sh
xcrun simctl location "$SIM" set 19.4326,-99.1332   # CDMX
```

## 4. Seed GPS-tagged photos (for photo/scanner features)

`simctl addmedia` preserves EXIF. Generate tagged JPEGs with sips + exiftool if available, or a tiny swift script using ImageIO to write `kCGImagePropertyGPSDictionary`. Then:

```sh
xcrun simctl addmedia "$SIM" /path/to/tagged-*.jpg
```

Grant photo access when the app prompts, or pre-approve:
`xcrun simctl privacy "$SIM" grant photos rojo.happy-places-moments`
(also `grant location` for location prompts).

## 5. Data-safety check (required for any model/store change)

Install and run the PREVIOUS build first, create places, then upgrade-install the new build and confirm existing data survives. Never reset the DB.

## 6. What to verify per area

- **New place flow**: map opens on user location, sheet appears, save creates list row with icon+color.
- **Place detail**: edit name/story/icon/color, add & delete photo, Done persists, back-swipe mid-edit doesn't half-persist.
- **Map tab**: markers tinted correctly; tapping marker opens preview sheet and re-centers camera; switching markers re-centers.
- **Photo import/scan**: photos with GPS produce correct coordinates (check against seeded EXIF values).
