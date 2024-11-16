//
//  CacheProvider.swift
//  SpendiQ
//
//  Created by Juan Salguero on 15/11/24.
//

import Foundation

final class CacheProvider {
    static let shared = CacheProvider()
    
    private let memoryCache = NSCache<NSString, AnyObject>()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    

    func setMemoryCache<T: AnyObject>(key: String, value: T) {
        memoryCache.setObject(value, forKey: key as NSString)
    }
    
    func getMemoryCache<T: AnyObject>(key: String) -> T? {
        return memoryCache.object(forKey: key as NSString) as? T
    }
    

    
    func setPersistentCache<T: Codable>(key: String, value: T) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func getPersistentCache<T: Codable>(key: String, type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return decoded
    }
    
    func clearCache(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        userDefaults.removeObject(forKey: key)
    }
}
