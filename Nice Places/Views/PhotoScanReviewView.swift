//
//  PhotoScanReviewView.swift
//  Nice Places
//
//  Review screen for places detected in the photo library. Nothing is
//  added unless explicitly selected (photos exist of places never visited).
//

import SwiftUI
import SwiftData
import CoreLocation

struct PhotoScanReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var places: [Place]

    @State private var scanner = PhotoPlacesScanner()

    private var selectedCount: Int {
        scanner.candidates.filter(\.isSelected).count
    }

    var body: some View {
        NavigationStack {
            Group {
                switch scanner.phase {
                case .idle, .scanning:
                    ProgressView("Looking through your photos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .denied:
                    ContentUnavailableView(label: {
                        Label("No photo access", systemImage: "photo.on.rectangle.angled")
                    }, description: {
                        Text("Allow photo access in Settings to find places you've been.")
                    })
                case .empty:
                    ContentUnavailableView(label: {
                        Label("No new places found", systemImage: "sparkles")
                    }, description: {
                        Text("Photos with location data near places you already saved are skipped.")
                    })
                case .ready:
                    reviewList
                }
            }
            .navigationTitle("Places from Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if scanner.phase == .ready {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(selectedCount == scanner.candidates.count ? "Deselect All" : "Select All") {
                            let select = selectedCount != scanner.candidates.count
                            for index in scanner.candidates.indices {
                                scanner.candidates[index].isSelected = select
                            }
                        }
                        .accessibilityIdentifier("selectAllButton")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if scanner.phase == .ready {
                    Button {
                        addSelectedPlaces()
                    } label: {
                        Text(selectedCount == 0 ? "Select places to add" : "Add \(selectedCount) place\(selectedCount == 1 ? "" : "s")")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCount == 0)
                    .accessibilityIdentifier("addSelectedPlacesButton")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(.thinMaterial)
                }
            }
        }
        .task {
            await scanner.start(existingPlaces: places.map(\.coordinate))
        }
    }

    private var reviewList: some View {
        List($scanner.candidates) { $candidate in
            PhotoSuggestionRow(candidate: $candidate)
                .task {
                    await scanner.geocodeIfNeeded(candidate.id)
                }
        }
        .listStyle(.plain)
    }

    private func addSelectedPlaces() {
        for candidate in scanner.candidates where candidate.isSelected {
            let name = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let place = Place(color: candidate.color.rawValue,
                              // The place's date is when you were actually there.
                              createdDate: candidate.earliestDate ?? Date(),
                              icon: candidate.icon,
                              latitude: candidate.coordinate.latitude,
                              longitude: candidate.coordinate.longitude,
                              name: name.isEmpty ? "Happy Place" : name,
                              text: "")
            context.insert(place)
        }
        // Persist immediately — autosave may not fire before the app goes away.
        try? context.save()
        dismiss()
    }
}

// MARK: - Row

private struct PhotoSuggestionRow: View {
    @Binding var candidate: PlaceSuggestionCandidate

    private var subtitle: String {
        var parts = ["\(candidate.photoCount) photo\(candidate.photoCount == 1 ? "" : "s")"]
        if candidate.distinctDays > 1 {
            parts.append("\(candidate.distinctDays) visits")
        }
        if let earliest = candidate.earliestDate {
            parts.append(earliest.formatted(.dateTime.month().year()))
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.bouncy) {
                    candidate.isSelected.toggle()
                }
            } label: {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(candidate.isSelected ? candidate.color.color : Color.secondary)
            }
            .buttonStyle(.plain)

            AssetThumbnail(assetIdentifier: candidate.assetIdentifiers.first)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Name this place", text: $candidate.name)
                    .font(.headline)
                    .onChange(of: candidate.name) { _, _ in
                        candidate.userEditedName = true
                    }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PlaceIconBadge(icon: candidate.icon, color: candidate.color.color, size: 36)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thumbnail

private struct AssetThumbnail: View {
    let assetIdentifier: String?

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task {
            guard image == nil, let assetIdentifier else { return }
            image = await PhotoPlacesScanner.thumbnail(for: assetIdentifier, side: 56)
        }
    }
}
