//
//  PhotoPickerView.swift
//  Nice Places
//
//  Created for Happy Places
//

import SwiftUI
import PhotosUI
import Photos
import CoreLocation

struct PhotoPickerView: View {
    @Binding var selectedPhotos: [PlacePhoto]
    let placeLatitude: Double
    let placeLongitude: Double
    let locationTolerance: Double = 100.0 // meters

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            // Camera button
            Button(action: {
                showingCamera = true
            }) {
                Label("Camera", systemImage: "camera.fill")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .cornerRadius(12)
            }

            // Photo library button
            PhotosPicker(selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images) {
                Label("Library", systemImage: "photo.on.rectangle")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .cornerRadius(12)
            }
        }
        .onChange(of: selectedItems) {
            Task {
                await loadPhotos()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(placeLatitude: placeLatitude,
                      placeLongitude: placeLongitude,
                      locationTolerance: locationTolerance) { photo in
                if let photo = photo {
                    selectedPhotos.append(photo)
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
        for item in selectedItems {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }

            // Extract location from photo metadata
            if let photoLocation = await extractLocation(from: item) {
                let distance = calculateDistance(
                    lat1: placeLatitude,
                    lon1: placeLongitude,
                    lat2: photoLocation.latitude,
                    lon2: photoLocation.longitude
                )

                if distance <= locationTolerance {
                    // Location is within tolerance
                    let photo = PlacePhoto(
                        imageData: data,
                        addedDate: Date(),
                        photoLatitude: photoLocation.latitude,
                        photoLongitude: photoLocation.longitude
                    )
                    selectedPhotos.append(photo)
                } else {
                    // Location is too far
                    locationAlertMessage = "This photo was taken \(Int(distance))m away from this place. Only photos taken within \(Int(locationTolerance))m can be added."
                    showingLocationAlert = true
                }
            } else {
                // No location metadata, allow it
                let photo = PlacePhoto(imageData: data, addedDate: Date())
                selectedPhotos.append(photo)
            }
        }

        selectedItems.removeAll()
    }

    private func extractLocation(from item: PhotosPickerItem) async -> CLLocationCoordinate2D? {
        // Try to get the asset identifier and fetch the PHAsset
        guard let identifier = item.itemIdentifier else {
            return nil
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            return nil
        }

        return asset.location?.coordinate
    }

    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let coordinate1 = CLLocation(latitude: lat1, longitude: lon1)
        let coordinate2 = CLLocation(latitude: lat2, longitude: lon2)
        return coordinate1.distance(from: coordinate2)
    }
}

// Custom camera view
struct CameraView: UIViewControllerRepresentable {
    let placeLatitude: Double
    let placeLongitude: Double
    let locationTolerance: Double
    let completion: (PlacePhoto?) -> Void

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

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[.originalImage] as? UIImage,
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                parent.completion(nil)
                return
            }

            // Get current location for the photo
            let locationManager = CLLocationManager()
            if let currentLocation = locationManager.location {
                let distance = currentLocation.distance(
                    from: CLLocation(latitude: parent.placeLatitude, longitude: parent.placeLongitude)
                )

                if distance <= parent.locationTolerance {
                    let photo = PlacePhoto(
                        imageData: imageData,
                        addedDate: Date(),
                        photoLatitude: currentLocation.coordinate.latitude,
                        photoLongitude: currentLocation.coordinate.longitude
                    )
                    parent.completion(photo)
                } else {
                    // Location validation failed
                    parent.completion(nil)
                }
            } else {
                // No location available, still add the photo
                let photo = PlacePhoto(imageData: imageData, addedDate: Date())
                parent.completion(photo)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
        }
    }
}

