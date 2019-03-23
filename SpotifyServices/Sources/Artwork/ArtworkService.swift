//
//  ArtworkService.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

public class ArtworkService {
    
    public static let shared = ArtworkService()
    
    @discardableResult
    public func requestArtwork(from images: [Image], storageClass: LocalStorageClass, preferredWidth: CGFloat, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard let imageUrl = images.preferredImage(matchingWidth: preferredWidth)?.url else {
            completion(nil)
            return nil
        }
        
        guard let identifier = imageUrl.absoluteString.data(using: .utf8)?.base64EncodedString() else {
            completion(nil)
            return nil
        }
        
        if let cachedImage = cachedArtwork(for: identifier) {
            completion(cachedImage)
            return nil
        } else {
            let task = URLSession.shared.dataTask(with: imageUrl) { data, resp, error in
                guard let data = data, let image = UIImage(data: data) else {
                    completion(nil)
                    return
                }
                
                LocalStorageManager.shared.saveArtworkData(
                    storageClass: storageClass,
                    identifier: identifier,
                    data: data
                )
                completion(image)
            }
            
            task.resume()
            return task
        }
    }
    
    @discardableResult
    public func requestArtworkFor(_ track: Track, storageClass: LocalStorageClass, preferredWidth: CGFloat, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        return requestArtwork(from: track.album.images, storageClass: storageClass, preferredWidth: preferredWidth, completion: completion)
    }
    
    public func cachedArtwork(from images: [Image], preferredWidth: CGFloat) -> UIImage? {
        guard let identifier = images.preferredImage(matchingWidth: preferredWidth)?.url.absoluteString.data(using: .utf8)?.base64EncodedString() else {
            return nil
        }
        
        return cachedArtwork(for: identifier)
    }
    
    public func cachedArtwork(for identifier: String) -> UIImage? {
        if let data = LocalStorageManager.shared.artworkData(storageClass: .download, identifier: identifier) {
            return UIImage(data: data)
        } else if let data = LocalStorageManager.shared.artworkData(storageClass: .temporary, identifier: identifier) {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
}

// MARK: - Download Extension

extension ArtworkService {
    
    @discardableResult
    func requestDownloadArtwork(from images: [Image], preferredWidth: CGFloat, urlSession: URLSession) -> (URLSessionDownloadTask, String)? {
        guard let imageUrl = images.preferredImage(matchingWidth: preferredWidth)?.url else {
            return nil
        }
        
        guard let identifier = imageUrl.absoluteString.data(using: .utf8)?.base64EncodedString() else {
            return nil
        }
        
        if cachedArtwork(for: identifier) != nil {
            return nil
        } else {
            let task = urlSession.downloadTask(with: imageUrl)
            return (task, identifier)
        }
    }
    
    func migrateDownloadedArtworkFile(_ identifier: String, location: URL) {
        LocalStorageManager.shared.moveArtwork(storageClass: .download, identifier: identifier, location: location)
    }
}
