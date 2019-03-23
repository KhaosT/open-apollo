//
//  LocalStorageManager.swift
//  Apollo
//
//  Created by Khaos Tian on 10/27/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public class LocalStorageManager {
    
    public static let shared = LocalStorageManager()
    
    private let temporaryStorageLocation: URL? = {
        do {
            return try FileManager.default
                .url(
                    for: .cachesDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                .appendingPathComponent(Constants.contentDirectory, isDirectory: true)
        } catch {
            return nil
        }
    }()
    
    private let downloadStorageLocation: URL? = {
        do {
            return try FileManager.default
                .url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                .appendingPathComponent(Constants.contentDirectory, isDirectory: true)
        } catch {
            return nil
        }
    }()
    
    init() {
        setupContentDirectories()
    }
}

// MARK: - Audio

extension LocalStorageManager {
    
    func audioFileStorageLocation(for storageClass: LocalStorageClass) -> URL {
        let locationUrl: URL = {
            switch storageClass {
            case .temporary:
                return temporaryStorageLocation!.appendingPathComponent(Constants.audioDirectory, isDirectory: true)
            case .download:
                return downloadStorageLocation!.appendingPathComponent(Constants.audioDirectory, isDirectory: true)
            }
        }()
        
        if !FileManager.default.fileExists(atPath: locationUrl.path) {
            do {
                try FileManager.default.createDirectory(at: locationUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
        
        return locationUrl
    }
}

// MARK: - Artwork

extension LocalStorageManager {
    
    private func artworkStorageLocation(for storageClass: LocalStorageClass) -> URL {
        let locationUrl: URL = {
            switch storageClass {
            case .temporary:
                return temporaryStorageLocation!.appendingPathComponent(Constants.artworkDirectory, isDirectory: true)
            case .download:
                return downloadStorageLocation!.appendingPathComponent(Constants.artworkDirectory, isDirectory: true)
            }
        }()
        
        if !FileManager.default.fileExists(atPath: locationUrl.path) {
            do {
                try FileManager.default.createDirectory(at: locationUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
        
        return locationUrl
    }
    
    func saveArtworkData(storageClass: LocalStorageClass, identifier: String, data: Data) {
        let targetUrl = artworkStorageLocation(for: storageClass).appendingPathComponent(identifier)
        
        do {
            try data.write(to: targetUrl, options: [])
        } catch {
            NSLog("Write Failure: \(error)")
        }
    }
    
    func moveArtwork(storageClass: LocalStorageClass, identifier: String, location: URL) {
        let targetLocation = artworkStorageLocation(for: storageClass).appendingPathComponent(identifier)
        
        do {
            try FileManager.default.moveItem(at: location, to: targetLocation)
        } catch {
            NSLog("[Download] Unexpect error occus when moving artwork file, error: \(error)")
        }
    }
    
    func artworkData(storageClass: LocalStorageClass, identifier: String) -> Data? {
        let targetUrl = artworkStorageLocation(for: storageClass).appendingPathComponent(identifier)
        
        guard FileManager.default.fileExists(atPath: targetUrl.path) else {
            return nil
        }
        
        do {
            return try Data(contentsOf: targetUrl)
        } catch {
            NSLog("Artwork Read Failure: \(error)")
            return nil
        }
    }
}

// MARK: - Playlist

extension LocalStorageManager {
    
    private func playlistStorageLocation() -> URL {
        let locationUrl = downloadStorageLocation!.appendingPathComponent(Constants.playlistDirectory, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: locationUrl.path) {
            do {
                try FileManager.default.createDirectory(at: locationUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
        
        return locationUrl
    }
    
    func savedPlaylists() -> [Playlist] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: playlistStorageLocation(), includingPropertiesForKeys: nil, options: [])
            return try contents.map { try JSONDecoder().decode(Playlist.self, from: Data(contentsOf: $0)) }
        } catch {
            NSLog("Read Saved Playlists Failure: \(error)")
            return []
        }
    }
    
    func savePlaylist(_ playlist: Playlist) {
        let targetUrl = playlistStorageLocation().appendingPathComponent(playlist.id)
        
        do {
            let jsonData = try JSONEncoder().encode(playlist)
            try jsonData.write(to: targetUrl, options: [])
        } catch {
            NSLog("Write Failure: \(error)")
        }
    }
}

// MARK: - Track

extension LocalStorageManager {
    
    private func trackItemCacheStorageLocation() -> URL {
        let locationUrl = temporaryStorageLocation!.appendingPathComponent(Constants.trackDirectory, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: locationUrl.path) {
            do {
                try FileManager.default.createDirectory(at: locationUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
        
        return locationUrl
    }
    
    public func cacheTrack(track: Track) {
        let targetUrl = trackItemCacheStorageLocation().appendingPathComponent(track.id)
        
        do {
            let jsonData = try JSONEncoder().encode(track)
            try jsonData.write(to: targetUrl, options: [])
        } catch {
            NSLog("Write Failure: \(error)")
        }
    }
    
    public func cachedTrack(trackId: String) -> Track? {
        let targetUrl = trackItemCacheStorageLocation().appendingPathComponent(trackId)
        
        guard FileManager.default.fileExists(atPath: targetUrl.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: targetUrl)
            return try JSONDecoder().decode(Track.self, from: data)
        } catch {
            NSLog("Track Read Failure: \(error)")
            return nil
        }
    }
}

// MARK: - Track Info

extension LocalStorageManager {
    
    private func trackInfoStorageLocation(for storageClass: LocalStorageClass) -> URL {
        let locationUrl: URL = {
            switch storageClass {
            case .temporary:
                return temporaryStorageLocation!.appendingPathComponent(Constants.trackInfoDirectory, isDirectory: true)
            case .download:
                return downloadStorageLocation!.appendingPathComponent(Constants.trackInfoDirectory, isDirectory: true)
            }
        }()
        
        if !FileManager.default.fileExists(atPath: locationUrl.path) {
            do {
                try FileManager.default.createDirectory(at: locationUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
        
        return locationUrl
    }
    
    func saveTrackInfo(storageClass: LocalStorageClass, trackInfo: TrackFileInfo) {
        let targetUrl = trackInfoStorageLocation(for: storageClass).appendingPathComponent(trackInfo.trackId)

        do {
            let jsonData = try JSONEncoder().encode(trackInfo)
            try jsonData.write(to: targetUrl, options: [])
        } catch {
            NSLog("Write Failure: \(error)")
        }
    }

    func trackInfo(storageClass: LocalStorageClass, trackId: String) -> TrackFileInfo? {
        let targetUrl = trackInfoStorageLocation(for: storageClass).appendingPathComponent(trackId)

        guard FileManager.default.fileExists(atPath: targetUrl.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: targetUrl)
            return try JSONDecoder().decode(TrackFileInfo.self, from: data)
        } catch {
            NSLog("TrackInfo Read Failure: \(error)")
            return nil
        }
    }
}

// MARK: - Deletion

extension LocalStorageManager {
    
    public func evictTemporaryStorage() {
        do {
            if FileManager.default.fileExists(atPath: audioFileStorageLocation(for: .temporary).path) {
                try FileManager.default.removeItem(at: audioFileStorageLocation(for: .temporary))
            }
            
            if FileManager.default.fileExists(atPath: trackInfoStorageLocation(for: .temporary).path) {
                try FileManager.default.removeItem(at: trackInfoStorageLocation(for: .temporary))
            }
            
            if FileManager.default.fileExists(atPath: trackItemCacheStorageLocation().path) {
                try FileManager.default.removeItem(at: trackItemCacheStorageLocation())
            }
            
            if FileManager.default.fileExists(atPath: artworkStorageLocation(for: .temporary).path) {
                try FileManager.default.removeItem(at: artworkStorageLocation(for: .temporary))
            }
        } catch {
            NSLog("Cache Eviction Error: \(error)")
        }
    }
    
    public func evictDownloadStorage() {
        do {
            if FileManager.default.fileExists(atPath: audioFileStorageLocation(for: .download).path) {
                try FileManager.default.removeItem(at: audioFileStorageLocation(for: .download))
            }
            
            if FileManager.default.fileExists(atPath: trackInfoStorageLocation(for: .download).path) {
                try FileManager.default.removeItem(at: trackInfoStorageLocation(for: .download))
            }
            
            if FileManager.default.fileExists(atPath: playlistStorageLocation().path) {
                try FileManager.default.removeItem(at: playlistStorageLocation())
            }
            
            if FileManager.default.fileExists(atPath: artworkStorageLocation(for: .download).path) {
                try FileManager.default.removeItem(at: artworkStorageLocation(for: .download))
            }
        } catch {
            NSLog("Download Eviction Error: \(error)")
        }
    }
}

// MARK: - Helper

extension LocalStorageManager {
    
    private func setupContentDirectories() {
        if let temporaryStorageLocation = temporaryStorageLocation,
            !FileManager.default.fileExists(atPath: temporaryStorageLocation.path) {
            
            do {
                try FileManager.default.createDirectory(at: temporaryStorageLocation, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
        
        if let downloadStorageLocation = downloadStorageLocation,
            !FileManager.default.fileExists(atPath: downloadStorageLocation.path) {
            
            do {
                try FileManager.default.createDirectory(at: downloadStorageLocation, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Creation Error: \(error)")
            }
        }
    }
}

// MARK: - Constants

extension LocalStorageManager {
    
    private struct Constants {
        static let contentDirectory = "apollo"
        static let audioDirectory = "audio"
        static let artworkDirectory = "artwork"
        static let playlistDirectory = "playlist"
        static let trackInfoDirectory = "trackinfo"
        static let trackDirectory = "track"
    }
}
