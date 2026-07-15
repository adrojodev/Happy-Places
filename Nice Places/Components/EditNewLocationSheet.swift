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

    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

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
                    HStack {
                        Text(placeName == "" ? "Save this place" : placeName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        SelectIconButton(selectedIcon: $selectedIcon, selectedColor: $selectedColor)
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

                                TextField("Tell your story here", text: $placeStory, axis: .vertical)
                                    .lineLimit(3...5)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.foreground.opacity(0.15))
                                    .cornerRadius(16.0)
                                    .focused($isStoryFocused)
                                VStack(alignment: .leading, spacing: 8) {
                                    if selectedPhotos.isEmpty {
                                        // Full-width rectangle when no photos
                                        PhotoPickerButton(selectedPhotos: $selectedPhotos,
                                                        placeLatitude: currentLatitude,
                                                        placeLongitude: currentLongitude,
                                                        isEmpty: true,
                                                        selectedColor: selectedColor)
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

                                                // Add photo button (square)
                                                PhotoPickerButton(selectedPhotos: $selectedPhotos,
                                                                placeLatitude: currentLatitude,
                                                                placeLongitude: currentLongitude,
                                                                isEmpty: false,
                                                                selectedColor: selectedColor)
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
                                dismiss()
                            } label: {
                                Text("Save Place")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding([.vertical], 12)
                                    .foregroundStyle(.background)
                                    .cornerRadius(16)
                                
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedColor.color)
                            .disabled(placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
    }
}

//MARK: - PhotoPickerButton
struct PhotoPickerButton: View {
    @Binding var selectedPhotos: [PlacePhoto]
    let placeLatitude: Double
    let placeLongitude: Double
    let isEmpty: Bool // true = full-width rectangle, false = square
    let selectedColor: PlaceColor
    let locationTolerance: Double = 500.0 // meters

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
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showingPhotoPicker,
                     selection: $selectedItems,
                     maxSelectionCount: 10,
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
        var rejectionMessages: [String] = []

        for item in selectedItems {
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
                        photoLongitude: photoLocation.longitude
                    )
                    selectedPhotos.append(photo)
                } else {
                    rejectionMessages.append("A photo was taken \(Int(distance))m away from this place. Only photos taken within \(Int(locationTolerance))m can be added.")
                }
            } else {
                rejectionMessages.append("A photo has no location data. Please select photos taken at this place.")
            }
        }

        selectedItems.removeAll()

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
