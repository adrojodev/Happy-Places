//
//  PhotoScanReviewView.swift
//  Nice Places
//
//  Guided flow for finding places in the photo library:
//  explain -> confirm -> scan (with progress) -> review (opt-in) -> done.
//  Nothing is added unless explicitly selected.
//

import SwiftUI
import SwiftData
import CoreLocation
import UIKit

struct PhotoScanReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var places: [Place]

    @State private var scanner = PhotoPlacesScanner()
    @State private var addedCount: Int?

    private var selectedCount: Int {
        scanner.candidates.filter(\.isSelected).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if let addedCount {
                    successView(count: addedCount)
                } else {
                    switch scanner.phase {
                    case .idle:
                        introView
                    case .scanning:
                        scanningView
                    case .denied:
                        deniedView
                    case .empty:
                        emptyView
                    case .ready:
                        reviewList
                    }
                }
            }
            .navigationTitle(scanner.phase == .ready ? "Pick your places" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if addedCount == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
                if scanner.phase == .ready && addedCount == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(selectedCount == scanner.candidates.count ? "Deselect All" : "Select All") {
                            let select = selectedCount != scanner.candidates.count
                            withAnimation(.bouncy) {
                                for index in scanner.candidates.indices {
                                    scanner.candidates[index].isSelected = select
                                }
                            }
                        }
                        .accessibilityIdentifier("selectAllButton")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if scanner.phase == .ready && addedCount == nil {
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
        .animation(.spring(duration: 0.4), value: scanner.phase)
        .animation(.spring(duration: 0.4), value: addedCount)
        .interactiveDismissDisabled(scanner.phase == .scanning)
    }

    // MARK: Intro — explain the feature and ask for an explicit go

    private var introView: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 130, height: 130)
                Image(systemName: "photo.stack")
                    .font(.system(size: 52))
                    .foregroundStyle(.green.gradient)
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse, options: .repeating)
                    .offset(x: 48, y: -42)
            }
            .padding(.bottom, 24)

            Text("Find your Happy Places")
                .font(.title)
                .fontWeight(.bold)
            Text("hiding in your photo library")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 20) {
                IntroFeatureRow(icon: "location.magnifyingglass",
                                tint: .blue,
                                title: "Scans photos with a location",
                                subtitle: "Only photos that carry GPS info are looked at — right on this device.")
                IntroFeatureRow(icon: "mappin.and.ellipse",
                                tint: .orange,
                                title: "Groups them into places",
                                subtitle: "Photos taken at the same spot become one suggestion, with a name, icon and color picked for you.")
                IntroFeatureRow(icon: "checklist",
                                tint: .green,
                                title: "You decide what gets added",
                                subtitle: "Review every suggestion and pick the places you actually visited. Nothing is saved without you.")
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)

            Spacer()
            Spacer()

            Button {
                Task {
                    await scanner.start(existingPlaces: places.map(\.coordinate))
                }
            } label: {
                Label("Scan My Photos", systemImage: "sparkles")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("startScanButton")
            .padding(.horizontal, 24)

            Text("Your photos never leave your device.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }

    // MARK: Scanning — live progress

    private var scanningView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.green.gradient)
                .symbolEffect(.pulse, options: .repeating)

            Text("Looking through your photos...")
                .font(.headline)

            ProgressView(value: scanner.scanProgress)
                .progressViewStyle(.linear)
                .tint(.green)
                .frame(maxWidth: 220)

            Text("Grouping photos into the places you've been")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Denied — invite to fix it in Settings

    private var deniedView: some View {
        ContentUnavailableView(label: {
            Label("No photo access", systemImage: "photo.on.rectangle.angled")
        }, description: {
            Text("Allow photo access so Happy Places can find the places you've been.")
        }, actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        })
    }

    private var emptyView: some View {
        ContentUnavailableView(label: {
            Label("No new places found", systemImage: "sparkles")
        }, description: {
            Text("Photos without location data are skipped, and so are places you already saved.")
        })
    }

    // MARK: Review

    private var reviewList: some View {
        List($scanner.candidates) { $candidate in
            PhotoSuggestionRow(candidate: $candidate)
                .task {
                    await scanner.geocodeIfNeeded(candidate.id)
                }
        }
        .listStyle(.plain)
    }

    // MARK: Success

    private func successView(count: Int) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green.gradient)
                .symbolEffect(.bounce, value: addedCount)
            Text("Added \(count) happy place\(count == 1 ? "" : "s")!")
                .font(.title2)
                .fontWeight(.bold)
            Text("You'll find them in your list and on the map.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
    }

    private func addSelectedPlaces() {
        let selected = scanner.candidates.filter(\.isSelected)
        for candidate in selected {
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

        withAnimation(.bouncy) {
            addedCount = selected.count
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            dismiss()
        }
    }
}

// MARK: - Intro feature row

private struct IntroFeatureRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
                    .contentTransition(.symbolEffect(.replace))
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
