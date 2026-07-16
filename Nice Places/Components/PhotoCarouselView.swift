//
//  PhotoCarouselView.swift
//  Nice Places
//
//  Full-screen swipeable preview of a photo cluster, so you can look at the
//  pictures and remember which place a suggestion is.
//

import SwiftUI
import UIKit

struct PhotoCarouselView: View {
    let title: String
    let assetIdentifiers: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var selection = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(Array(assetIdentifiers.enumerated()), id: \.offset) { index, identifier in
                    CarouselPhoto(assetIdentifier: identifier)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: assetIdentifiers.count > 1 ? .always : .never))
            .ignoresSafeArea()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if assetIdentifiers.count > 1 {
                        Text("\(selection + 1) of \(assetIdentifiers.count)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .accessibilityLabel("Close photos")
                .accessibilityIdentifier("closeCarouselButton")
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .accessibilityIdentifier("photoCarouselOverlay")
    }
}

private struct CarouselPhoto: View {
    let assetIdentifier: String

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard image == nil else { return }
            image = await PhotoPlacesScanner.fullImage(for: assetIdentifier)
        }
    }
}

#Preview {
    PhotoCarouselView(title: "Taquería El Paisa", assetIdentifiers: ["a", "b"])
}
