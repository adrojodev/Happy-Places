//
//  CustomSheetView.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import SwiftUI
import PhotosUI
import Photos
import CoreLocation
import SwiftData
import UIKit

struct EditNewLocationSheet: View {
    @Binding var latitude: CLLocationDegrees?
    @Binding var longitude: CLLocationDegrees?
    @Binding var isShowing: Bool
    @Binding var selectedColor: PlaceColor

    @FocusState private var isNameFocused: Bool
    @FocusState private var isStoryFocused: Bool

    @State private var placeName: String = ""
    @State private var placeStory: String = ""
    @State private var selectedIcon: String = "mappin"
    @State private var selectedPhotos: [PlacePhoto] = []
    @State private var userCustomizedIcon = false
    @State private var lastSuggestion: PlaceClassifier.Suggestion?
    @State private var nearbyPlace: Place?
    @State private var ignoredNearbyPlaceID: PersistentIdentifier?
    @State private var pendingImports: Int = 0

    @Query private var places: [Place]

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

    /// Same radius the photo scanner uses to treat a spot as an
    /// already-saved place.
    static let duplicateRadiusMeters: Double = 150

    init(latitude: Binding<CLLocationDegrees?>, longitude: Binding<CLLocationDegrees?>, isShowing: Binding<Bool>, selectedColor: Binding<PlaceColor>, preloadedPhoto: PlacePhoto? = nil) {
        self._latitude = latitude
        self._longitude = longitude
        self._isShowing = isShowing
        self._selectedColor = selectedColor

        // Initialize with preloaded photo if provided
        if let photo = preloadedPhoto {
            self._selectedPhotos = State(initialValue: [photo])
        }
    }

    // Computed property to get current coordinates
    private var currentLatitude: CLLocationDegrees {
        latitude ?? 0
    }

    private var currentLongitude: CLLocationDegrees {
        longitude ?? 0
    }
    
    var body: some View {
        ZStack (alignment: .bottom) {
            if isShowing {
                VStack (spacing: 16) {
                    if let nearby = nearbyPlace, nearby.persistentModelID != ignoredNearbyPlaceID {
                        duplicateWarning(for: nearby)
                    }
                    HStack {
                        Text(placeName == "" ? "Save this place" : placeName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        SelectIconButton(selectedIcon: $selectedIcon, selectedColor: $selectedColor)
                            .overlay(alignment: .topLeading) {
                                if lastSuggestion != nil && !userCustomizedIcon {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                        .foregroundStyle(selectedColor.color)
                                        .offset(x: -6, y: -4)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                    }
                    Form {
                        VStack (spacing: 16) {
                            VStack {
                                TextField("Name of this place", text: $placeName)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.foreground.opacity(0.15))
                                    .cornerRadius(16.0)
                                    .focused($isNameFocused)
                                    .accessibilityIdentifier("placeNameField")

                                TextField("Tell your story here", text: $placeStory, axis: .vertical)
                                    .lineLimit(3...5)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.foreground.opacity(0.15))
                                    .cornerRadius(16.0)
                                    .focused($isStoryFocused)
                                VStack(alignment: .leading, spacing: 8) {
                                    if selectedPhotos.isEmpty && pendingImports == 0 {
                                        // Full-width rectangle when no photos
                                        PhotoPickerButton(selectedPhotos: $selectedPhotos,
                                                        placeLatitude: currentLatitude,
                                                        placeLongitude: currentLongitude,
                                                        isEmpty: true,
                                                        selectedColor: selectedColor,
                                                        pendingImports: $pendingImports)
                                    } else {
                                        // Show "Photos" label and horizontal scroll with photos + add button
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(selectedPhotos) { photo in
                                                    if let imageData = photo.imageData,
                                                       let uiImage = UIImage(data: imageData) {
                                                        ZStack(alignment: .topTrailing) {
                                                            Image(uiImage: uiImage)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 80, height: 80)
                                                                .cornerRadius(8)
                                                                .clipped()

                                                            Button(action: {
                                                                selectedPhotos.removeAll { $0 === photo }
                                                            }) {
                                                                Image(systemName: "xmark")
                                                                    .foregroundColor(.red)
                                                                    .font(.caption)
                                                                    .fontWeight(.semibold)
                                                            }
                                                            .frame(width: 20, height: 20)
                                                            .background(.red.opacity(0.3), in: Circle())
                                                            .background(.ultraThinMaterial, in: Circle())
                                                            .padding(4)
                                                        }
                                                    }
                                                }

                                                // Loading previews for photos still importing
                                                ForEach(0..<pendingImports, id: \.self) { _ in
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(.quaternary)
                                                        .frame(width: 80, height: 80)
                                                        .overlay { ProgressView() }
                                                }

                                                // Add photo button (square)
                                                PhotoPickerButton(selectedPhotos: $selectedPhotos,
                                                                placeLatitude: currentLatitude,
                                                                placeLongitude: currentLongitude,
                                                                isEmpty: false,
                                                                selectedColor: selectedColor,
                                                                pendingImports: $pendingImports)
                                            }
                                        }
                                    }
                                }
                            }

                            

                            Button {
                                let place = Place(color: selectedColor.rawValue,
                                                  createdDate: Date(),
                                                  icon: selectedIcon,
                                                  latitude: currentLatitude,
                                                  longitude: currentLongitude,
                                                  name: placeName,
                                                  text: placeStory,
                                                  photos: selectedPhotos)

                                context.insert(place)
                                try? context.save()
                                dismiss()
                            } label: {
                                Text("Save Place")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding([.vertical], 12)
                                    .foregroundStyle(.background)
                                    .cornerRadius(16)
                                
                            }
                            .prominentActionStyle()
                            .tint(selectedColor.color)
                            .disabled(placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingImports > 0)
                            .accessibilityIdentifier("savePlaceButton")

                        }
                    }
                    .formStyle(.columns)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, isNameFocused || isStoryFocused ? 16 : 48)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(.rect(topLeadingRadius: 32.0, bottomLeadingRadius: 0.0, bottomTrailingRadius: 0.0, topTrailingRadius: 20.0))
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: isNameFocused)
                .animation(.easeInOut, value: isStoryFocused)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(isNameFocused || isStoryFocused ? .black.opacity(0.4) : .clear)
        .ignoresSafeArea(.container)
        .animation(.bouncy, value: isShowing)
        .animation(.easeInOut, value: isNameFocused)
        .animation(.easeInOut, value: isStoryFocused)
        .onChange(of: isShowing, initial: true) {
            updateNearbyPlace()
        }
        .onChange(of: latitude) {
            updateNearbyPlace()
        }
        .onChange(of: longitude) {
            updateNearbyPlace()
        }
        .onChange(of: placeName) {
            applySuggestionIfWanted()
        }
        .onChange(of: selectedIcon) {
            // Any change that didn't come from a suggestion is a manual pick;
            // stop suggesting from then on.
            if selectedIcon != (lastSuggestion?.icon ?? "mappin") {
                userCustomizedIcon = true
            }
        }
        .onChange(of: selectedColor) {
            if selectedColor != (lastSuggestion?.color ?? .green) {
                userCustomizedIcon = true
            }
        }
    }

    @ViewBuilder
    private func duplicateWarning(for nearby: Place) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PlaceIconBadge(icon: nearby.icon, color: nearby.uiColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hey, is this \(nearby.name)?")
                        .fontWeight(.semibold)
                    Text("You saved it \(nearby.formattedDate), right around here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                Button {
                    dismiss()
                } label: {
                    Text("Yes, that's it")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .prominentActionStyle()
                .buttonBorderShape(.capsule)
                .tint(nearby.uiColor)
                .accessibilityIdentifier("duplicatePlaceYesButton")

                Button {
                    withAnimation(.bouncy) {
                        ignoredNearbyPlaceID = nearby.persistentModelID
                    }
                } label: {
                    Text("No, it's new")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .secondaryActionStyle()
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("duplicatePlaceNoButton")
            }
        }
        .padding(12)
        .background(nearby.uiColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func updateNearbyPlace() {
        guard isShowing, let lat = latitude, let lon = longitude else { return }
        let here = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let closest = Self.nearestSavedPlace(to: here, in: places)
        if closest?.persistentModelID != nearbyPlace?.persistentModelID {
            withAnimation(.bouncy) {
                nearbyPlace = closest
            }
        }
    }

    /// The closest already-saved place within `meters`, or nil if none.
    static func nearestSavedPlace(to coordinate: CLLocationCoordinate2D,
                                  in places: [Place],
                                  within meters: Double = duplicateRadiusMeters) -> Place? {
        places
            .map { (place: $0, meters: PhotoProcessing.distanceMeters(from: coordinate, to: $0.coordinate)) }
            .filter { $0.meters <= meters }
            .min { $0.meters < $1.meters }?
            .place
    }

    private func applySuggestionIfWanted() {
        guard !userCustomizedIcon else { return }
        guard let suggestion = PlaceClassifier.suggest(for: placeName),
              suggestion != lastSuggestion else { return }
        lastSuggestion = suggestion
        withAnimation(.bouncy) {
            selectedIcon = suggestion.icon
            selectedColor = suggestion.color
        }
    }
}

//MARK: - PhotoPickerButton
struct PhotoPickerButton: View {
    @Binding var selectedPhotos: [PlacePhoto]
    let placeLatitude: Double
    let placeLongitude: Double
    let isEmpty: Bool // true = full-width rectangle, false = square
    let selectedColor: PlaceColor
    /// How many picked photos are still importing (drives loading previews
    /// and lets the parent disable its Done/Save button).
    @Binding var pendingImports: Int
    let locationTolerance: Double = 500.0 // meters

    /// Already-added photos that came from the library; shown preselected in
    /// the picker and excluded from the new-photo limit.
    private var preselectable: [PhotosPickerItem] {
        selectedPhotos.compactMap { photo in
            photo.assetIdentifier.map { PhotosPickerItem(itemIdentifier: $0) }
        }
    }

    @State private var showingActionSheet = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""

    var body: some View {
        Group {
            if isEmpty {
                // Full-width rectangle when no photos
                Button(action: {
                    showingActionSheet = true
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                        Text("Add Photos")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedColor.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(selectedColor.color.opacity(0.15))
                    .cornerRadius(12)
                }
            } else {
                // Square button when photos exist
                Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(selectedColor.color)
                        .frame(width: 80, height: 80)
                        .background(selectedColor.color.opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
        .confirmationDialog("", isPresented: $showingActionSheet, titleVisibility: .hidden) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                // Seed the picker with what's already added, so those photos
                // show their checkmarks and don't eat into the new-photo limit.
                selectedItems = preselectable
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showingPhotoPicker,
                     selection: $selectedItems,
                     maxSelectionCount: preselectable.count + 10,
                     matching: .images,
                     photoLibrary: .shared())
        .onChange(of: selectedItems) {
            Task {
                await loadPhotos()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(placeLatitude: placeLatitude,
                      placeLongitude: placeLongitude,
                      locationTolerance: locationTolerance) { result in
                switch result {
                case .captured(let photo):
                    selectedPhotos.append(photo)
                case .rejected(let distance):
                    locationAlertMessage = "That photo was taken \(Int(distance))m away from this place. Only photos taken within \(Int(locationTolerance))m can be added."
                    showingLocationAlert = true
                case .cancelled:
                    break
                }
                showingCamera = false
            }
        }
        .alert("Location Mismatch", isPresented: $showingLocationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(locationAlertMessage)
        }
    }

    private func loadPhotos() async {
        // Only import photos that aren't already on the place — the ones we
        // preselected come back in the confirmed selection too. When nothing
        // is new (e.g. the preselection seed itself), keep the selection so
        // the picker still shows the checkmarks.
        let existingIDs = Set(selectedPhotos.compactMap(\.assetIdentifier))
        let newItems = selectedItems.filter { item in
            guard let id = item.itemIdentifier else { return true }
            return !existingIDs.contains(id)
        }
        guard !newItems.isEmpty else { return }

        pendingImports = newItems.count
        defer {
            pendingImports = 0
            selectedItems.removeAll()
        }

        var rejectionMessages: [String] = []

        for item in newItems {
            defer { pendingImports = max(0, pendingImports - 1) }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let storableData = PhotoProcessing.storableImageData(from: data) else { continue }

            if let photoLocation = PhotoProcessing.location(from: item, imageData: data) {
                let distance = PhotoProcessing.distanceMeters(
                    from: CLLocationCoordinate2D(latitude: placeLatitude, longitude: placeLongitude),
                    to: photoLocation
                )

                if distance <= locationTolerance {
                    let photo = PlacePhoto(
                        imageData: storableData,
                        addedDate: Date(),
                        photoLatitude: photoLocation.latitude,
                        photoLongitude: photoLocation.longitude,
                        assetIdentifier: item.itemIdentifier
                    )
                    selectedPhotos.append(photo)
                } else {
                    rejectionMessages.append("A photo was taken \(Int(distance))m away from this place. Only photos taken within \(Int(locationTolerance))m can be added.")
                }
            } else {
                rejectionMessages.append("A photo has no location data. Please select photos taken at this place.")
            }
        }

        if !rejectionMessages.isEmpty {
            locationAlertMessage = rejectionMessages.joined(separator: "\n\n")
            showingLocationAlert = true
        }
    }
}

//MARK: - CameraView
enum CameraCaptureResult {
    case captured(PlacePhoto)
    case rejected(distanceMeters: Double)
    case cancelled
}

struct CameraView: UIViewControllerRepresentable {
    let placeLatitude: Double
    let placeLongitude: Double
    let locationTolerance: Double
    let completion: (CameraCaptureResult) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
        let parent: CameraView
        let locationManager: CLLocationManager
        var currentLocation: CLLocation?

        init(_ parent: CameraView) {
            self.parent = parent
            self.locationManager = CLLocationManager()
            super.init()
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            currentLocation = locations.last
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[.originalImage] as? UIImage,
                  let imageData = PhotoProcessing.storableImageData(from: image) else {
                parent.completion(.cancelled)
                return
            }

            if let userLocation = currentLocation {
                let distance = userLocation.distance(
                    from: CLLocation(latitude: parent.placeLatitude, longitude: parent.placeLongitude)
                )

                if distance <= parent.locationTolerance {
                    let photo = PlacePhoto(
                        imageData: imageData,
                        addedDate: Date(),
                        photoLatitude: userLocation.coordinate.latitude,
                        photoLongitude: userLocation.coordinate.longitude
                    )
                    parent.completion(.captured(photo))
                } else {
                    parent.completion(.rejected(distanceMeters: distance))
                }
            } else {
                // No GPS fix yet (common right after opening the camera):
                // keep the photo, just without coordinates.
                let photo = PlacePhoto(imageData: imageData, addedDate: Date())
                parent.completion(.captured(photo))
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(.cancelled)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Place.self, configurations: config)

    EditNewLocationSheet(latitude: .constant(12.64654), longitude: .constant(-122.86453), isShowing: .constant(true), selectedColor: .constant(PlaceColor.green))
        .modelContainer(container)
}
