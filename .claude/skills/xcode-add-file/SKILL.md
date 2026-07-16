---
name: xcode-add-file
description: Register a new (or remove a deleted) Swift file in Nice Places.xcodeproj/project.pbxproj. Required for every file added or deleted in this repo — nothing is auto-discovered.
---

# Registering files in project.pbxproj

This project uses the old pbxproj format (objectVersion 56). A Swift file on disk that is not referenced in project.pbxproj **silently doesn't compile** — every type in it is "not in scope".

## Adding a file (4 edits, one script)

Pick two fresh 24-hex-char IDs per file (one PBXBuildFile, one PBXFileReference). Convention used here: `E5AA0000000000000000XXNN`. Grep first to confirm they're unused.

1. **PBXBuildFile** section:
   `<BUILD_ID> /* File.swift in Sources */ = {isa = PBXBuildFile; fileRef = <REF_ID> /* File.swift */; };`
2. **PBXFileReference** section:
   `<REF_ID> /* File.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = File.swift; sourceTree = "<group>"; };`
3. **PBXGroup**: add `<REF_ID> /* File.swift */,` to the children of the group matching the file's directory (Views = `E50117242B76E81C00E00E5D`, Components = `E50117282B7730AF00E00E5D`, Models = `E56466822B77B7DF004E055F`, Data = `E564668B2B77D197004E055F`, Utils = `E5AA000000000000000000C1`, Shared = `E5AA0000000000000000F022`, Intents = `E5AA0000000000000000F023`, HappyPlacesWidgets = `E5AA0000000000000000F021`, app root "Nice Places" = `E50116F62B76E7BC00E00E5D`). New directory → create a new PBXGroup with `path = <DirName>;` and add it to the "Nice Places" group children.
4. **PBXSourcesBuildPhase**: add `<BUILD_ID> /* File.swift in Sources */,` to the app target phase `E50116F02B76E7BC00E00E5D` (tests target phase: `E50117002B76E7BD00E00E5D`, UI tests: `E501170A2B76E7BD00E00E5D`, widget extension: `E5AA0000000000000000F031`). Files in `Nice Places/Shared/` must be added to BOTH the app and widget Sources phases (one PBXBuildFile entry per target, same fileRef).

Do this with a small python3 heredoc using anchored `str.replace` (see git history of project.pbxproj for a worked example).

## Removing a file

Delete the file's PBXBuildFile line, PBXFileReference line, its group-children line, and its Sources-phase line.

## Verify

```sh
plutil -lint "Nice Places.xcodeproj/project.pbxproj"
xcodebuild -list -project "Nice Places.xcodeproj"   # parses = structure OK
```
Then build (see `build` skill).
