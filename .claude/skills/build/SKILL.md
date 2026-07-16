---
name: build
description: Build or test Happy Places for the iOS simulator. Use whenever compiling the app, running tests, or diagnosing build failures.
---

# Build & test Happy Places

## Commands

```sh
# Build (quiet; show only errors/warnings)
xcodebuild -project "Nice Places.xcodeproj" -scheme "Happy Places" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 \
  | grep -E "error:|warning:|BUILD"

# Run tests
xcodebuild -project "Nice Places.xcodeproj" -scheme "Happy Places" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test 2>&1 \
  | grep -E "error:|failed|passed|BUILD|TEST"
```

Run from the repo root. Scheme is `Happy Places`; test module is `Happy_Places`.

## Common failures

- **"Cannot find 'X' in scope" for a type that clearly exists** → the file defining X is not registered in project.pbxproj. Use the `xcode-add-file` skill.
- **Duplicate symbol / invalid redeclaration** → a type is defined in two files (this repo has had inline copies of types pasted into other files). Grep for the type name across `Nice Places/`.
- **SourceKit diagnostics in the editor are unreliable for unregistered files** (e.g. "No such module 'UIKit'") — trust `xcodebuild`, not single-file diagnostics.
- **`PhotosPickerItem` not found** → the file needs `import SwiftUI` in addition to `import PhotosUI` (cross-import overlay).
- After editing project.pbxproj, validate with `plutil -lint "Nice Places.xcodeproj/project.pbxproj"` and `xcodebuild -list -project "Nice Places.xcodeproj"` before building.
- **Code edits compile ("BUILD SUCCEEDED") but the running app / UI tests show old behavior** → the incremental build can relink a stale `Happy Places.debug.dylib` even though the `.o` recompiled with the change. Verify: `LANG=C grep -ac "<new string literal>" "<DerivedData>/Build/Products/Debug-iphonesimulator/Happy Places.app/Happy Places.debug.dylib"` (use a literal **longer than 15 bytes** — Swift inlines shorter ones and they never appear as bytes). If 0, run `xcodebuild ... clean build`. `strings` doesn't work on these binaries; use `grep -a` or python byte-search.
