//
//  ImageCacheManager.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 18/11/24.
//

import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager() // Sprint 3: Singleton
    private let cacheDirectory: URL

    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("OfferImages")
        
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func saveImage(_ image: UIImage, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        try? data.write(to: fileURL)
    }

    func loadImage(forKey key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        return UIImage(contentsOfFile: fileURL.path)
    }

    func deleteImage(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func clearCache(forKeys keys: [String]) {
        keys.forEach { deleteImage(forKey: $0) }
    }
}
