//
//  PhotoProcessing.swift
//  Nice Places
//
//  Shared helpers for photos: GPS extraction, distance, and downscaling.
//

import UIKit
import SwiftUI
import CoreLocation
import Photos
import PhotosUI
import ImageIO

enum PhotoProcessing {
    /// Stored photos are capped at this pixel size to keep SwiftData/CloudKit
    /// payloads (and the user's iCloud quota) reasonable.
    static let maxStoredPixelSize: CGFloat = 2048
    static let jpegQuality: CGFloat = 0.8

    /// Re-encodes image data as JPEG, downscaled so the longest side is at most
    /// `maxStoredPixelSize`. Returns nil if the data is not a decodable image.
    static func storableImageData(from data: Data) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxStoredPixelSize,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: jpegQuality)
    }

    /// Downscaled JPEG data for an in-memory image (camera captures).
    static func storableImageData(from image: UIImage) -> Data? {
        let largestSide = max(image.size.width, image.size.height) * image.scale
        guard largestSide > maxStoredPixelSize else {
            return image.jpegData(compressionQuality: jpegQuality)
        }
        let ratio = maxStoredPixelSize / largestSide
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: jpegQuality)
    }

    /// Location of a picked photo. Tries the PHAsset (requires the picker to be
    /// created with `photoLibrary: .shared()` so `itemIdentifier` is populated),
    /// then falls back to the EXIF GPS dictionary in the image data.
    static func location(from item: PhotosPickerItem, imageData: Data) -> CLLocationCoordinate2D? {
        if let identifier = item.itemIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            if let asset = fetchResult.firstObject, let location = asset.location {
                return location.coordinate
            }
        }

        if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
           let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
           let gpsData = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? Double,
           let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? Double,
           let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String {
            let finalLatitude = latitudeRef == "S" ? -latitude : latitude
            let finalLongitude = longitudeRef == "W" ? -longitude : longitude
            return CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
        }

        return nil
    }

    static func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}
