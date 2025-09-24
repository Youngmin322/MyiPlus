//
//  KingfisherCacheManager.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/29/25.
//

import Foundation
import Kingfisher

struct KingfisherCacheManager {
    
    static let shared = KingfisherCacheManager()
    
    private init() {
        configureCache()
    }
    
    private func configureCache() {
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        ImageCache.default.memoryStorage.config.countLimit = 100
        
        ImageCache.default.diskStorage.config.sizeLimit = 200 * 1024 * 1024
        ImageCache.default.diskStorage.config.expiration = .days(7)
    }
    
    func removeCache(for urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let resource = KF.ImageResource(downloadURL: url)
        
        KingfisherManager.shared.cache.removeImage(
            forKey: resource.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            fromMemory: true,
            fromDisk: true
        ) {
            print("캐시 삭제 완료: \(urlString)")
        }
    }
    
    func removeCache(for urlStrings: [String]) {
        urlStrings.forEach { removeCache(for: $0) }
    }
    
    func clearAllCache() {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache {
            print("전체 캐시 클리어 완료")
        }
    }
    
    func calculateCacheSize(completion: @escaping (Int) -> Void) {
        KingfisherManager.shared.cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                completion(Int(size))
            case .failure:
                completion(0)
            }
        }
    }
}

extension NoteViewModel {
    func refreshImageCache(for note: Note) {
        KingfisherCacheManager.shared.removeCache(for: note.imageURLs)
        
        NotificationCenter.default.post(
            name: Notification.Name("RefreshNoteImages"),
            object: note.id
        )
    }
}
