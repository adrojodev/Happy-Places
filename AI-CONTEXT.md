# Happy Places - AI Context

## Project Overview

**Happy Places** (internal name: "Nice Places") is a native iOS application currently published on the App Store. It allows users to save and remember meaningful locations with personal stories and memories. Users can mark special places on a map with custom icons, colors, and descriptions, creating a personal location journal.

## Tech Stack

- **Language**: Swift
- **Framework**: SwiftUI (iOS 18+)
- **Data Persistence**: SwiftData (Apple's modern data framework)
- **Cloud Sync**: iCloud CloudKit
- **Location Services**: CoreLocation & MapKit
- **Dependencies**: None (100% native Apple frameworks)

## Architecture

This is a standard SwiftUI application following modern iOS development best practices:

- **Pattern**: MVVM-like with SwiftUI
- **State Management**: @State, @Binding, @Environment
- **Navigation**: NavigationStack with TabView root
- **Data Layer**: SwiftData with @Query and @Environment(\.modelContext)

## Key Features

1. **Location Management**
   - Save locations with coordinates (latitude/longitude)
   - Add name and personal description/story for each place
   - Search functionality across saved places
   - Swipe-to-delete support

2. **Visual Customization**
   - 66 custom SF Symbol icons
   - 7 color themes (pink, red, orange, yellow, green, blue, purple)
   - Gradient backgrounds for icon display

3. **Map Integration**
   - Interactive map with markers for all saved places
   - Individual place map view with "Open in Maps" navigation
   - Camera positioning and smooth animations
   - Map preview sheets when tapping markers

4. **Cross-Device Sync**
   - iCloud CloudKit integration
   - Container: `iCloud.rojo.happy-places`
   - Automatic sync across user's devices

## Data Model

Primary model is `Place` (defined in `PlacesDataModel.swift`):

```swift
@Model
class Place {
    var color: String        // Color identifier for the place
    var createdDate: Date    // When the place was saved
    var icon: String         // SF Symbol name
    var latitude: Double     // Location coordinate
    var longitude: Double    // Location coordinate
    var name: String         // Place name
    var text: String         // User's story/description
    var photos: [PlacePhoto] // Array of photos for this place
}

@Model
class PlacePhoto {
    var imageData: Data       // JPEG image data
    var addedDate: Date       // When photo was added
    var photoLatitude: Double?  // Photo's GPS latitude (if available)
    var photoLongitude: Double? // Photo's GPS longitude (if available)
}
```

## Project Structure

```
Nice Places/
├── HappyPlacesApp.swift              # App entry point with SwiftData container
├── HappyPlacesView.swift             # Main TabView container (List & Map tabs)
├── Components/                        # Reusable UI components
│   ├── EditNewLocationSheet.swift    # Bottom sheet for creating places + PhotoPickerView + CameraView
│   ├── IconSelector.swift            # Icon and color picker modal
│   ├── PlaceItemView.swift           # List row item
│   ├── SelectIconButton.swift        # Button to open icon selector
│   └── PhotoPickerView.swift         # (Created but not in Xcode project - code merged into EditNewLocationSheet)
├── Data/                             # Static data
│   └── Icons.swift                   # Icon definitions & PlaceColor enum
├── Location/                         # Location services
│   └── LocationDataManager.swift     # CoreLocation manager
├── Models/                           # Data models
│   └── PlacesDataModel.swift         # Active SwiftData model
└── Views/                            # Main screens
    ├── LocationsListView.swift       # Scrollable list of all places
    ├── MapView.swift                 # Full-screen map for individual place
    ├── MarkersMapView.swift          # Map with markers for all places
    ├── NewLocationView.swift         # Create new location interface
    ├── PlaceMapPreview.swift         # Sheet preview on marker tap
    └── PlaceView.swift               # Detailed view/edit for single place
```

## Important Files

- `HappyPlacesApp.swift:5` - SwiftData model container configuration with CloudKit
- `PlacesDataModel.swift:12` - Main Place model definition
- `Icons.swift:11` - Icon data and PlaceColor enum (66 icons, 7 colors)
- `LocationDataManager.swift:10` - Location services manager
- `HappyPlacesView.swift:11` - Main navigation structure

## App Configuration

- **Bundle ID**: `rojo.happy-places-moments`
- **Version**: 1.1.4
- **Platform**: iPhone only, iOS 18+
- **Status**: Published on App Store

## Recent Development

Recent git commits show:
- Updated to iOS 18
- Added iCloud cloud storage
- Fixed location bugs
- Improved UI/UX with better animations
- Currently working on UI improvements (branch: `rojo/new-ui`)

## Recent Additions

- **Photo Support**: IMPLEMENTED! Places now support multiple photos with the following features:
  - Camera integration for taking photos on-site
  - Photo library picker for adding existing photos
  - Location validation: Photos must be taken within 100 meters of the place location
  - Photo metadata extraction to verify location from EXIF data
  - Multiple photos per place support
  - Photo preview in horizontal scroll view
  - Edit mode to add/remove photos

## Development Notes

- **Database**: NEVER RESET THE DB (per user instructions)
- **Code Style**: Standard Swift/SwiftUI conventions, nothing special or unconventional
- **Legacy Code**: `DataController.swift` and `Place.swift` (in Models/) appear to be legacy CoreData code that's no longer used but hasn't been removed
- The app uses standard iOS patterns throughout - straightforward SwiftUI implementation without custom frameworks or unusual architectural decisions
- **iCloud Sync**: Simple ModelContainer setup with automatic CloudKit sync. Auto-recovery if database is corrupted.
- **Photo Components**: PhotoPickerView and CameraView are defined in EditNewLocationSheet.swift (PhotoPickerView.swift exists but isn't in Xcode project)
- **Sync Status**: CloudKitSyncMonitor in HappyPlacesApp.swift, SyncStatusView components in IconSelector.swift
- **Schema Migration**: Using simple lightweight migration - SwiftData handles the `photos` array addition automatically for existing users

## Common Tasks

When working on this codebase:
- Place model changes require SwiftData migrations
- New features should integrate with existing CloudKit sync
- UI follows iOS design guidelines with Material backgrounds and standard components
- Location permissions are handled via LocationDataManager
- Icon/color customization uses the existing PlaceColor enum system
- **Adding photos**: Photos are validated to be within 100m of place location (configurable in PhotoPickerView.locationTolerance)
- **Photo storage**: Photos are stored as Data (JPEG, 0.8 quality) directly in SwiftData, automatically synced via iCloud
- **Permissions**: Camera and Photo Library permissions are configured in Nice-Places-Info.plist
