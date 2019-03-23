//
//  DownloadManager.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public class DownloadManager: NSObject {
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "app.awas.Spotify.download")
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.allowsCellularAccess = false
        configuration.waitsForConnectivity = true
        
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return urlSession
    }()
    
    public static let shared = DownloadManager()
    
    public func handleSessionUpdate(_ completion: (() -> Void)?) {
        guard let completion = completion else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
    }
    
    public func getCurrentTasks(_ responseHandler: @escaping ([URLSessionDownloadTask]) -> Void) {
        urlSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            DispatchQueue.main.async {
                responseHandler(downloadTasks)
            }
        }
    }
    
    public func download(with serviceProvider: SpotifyServiceProvider, playlist: SimplifiedPlaylist, completion: @escaping (Result<Void>) -> Void) {
        serviceProvider.getPlaylist(playlist.id) { [weak self] result in
            switch result {
            case .success(let playlist):
                LocalStorageManager.shared.savePlaylist(playlist)
                serviceProvider.tracksInfo(
                    for: Array(playlist.tracks.items.filter { !$0.isLocal }.map { $0.track.id }.prefix(upTo: min(30, playlist.tracks.items.count))),
                    completionHandler: { tracksInfoResult in
                        switch tracksInfoResult {
                        case .success(let tracksInfo):
                            self?.startDownload(with: serviceProvider, playlist: playlist, tracksInfo: tracksInfo, completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                )
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func startDownload(with serviceProvider: SpotifyServiceProvider, playlist: Playlist, tracksInfo: [TrackFileInfo], completion: @escaping (Result<Void>) -> Void) {
        guard !tracksInfo.isEmpty else {
            completion(.failure(E.unknownError))
            return
        }
        
        let group = DispatchGroup()
        
        var trackMaps: [String: Track] = [:]
        
        for track in playlist.tracks.items {
            guard !track.isLocal else {
                continue
            }
            
            trackMaps[track.track.id] = track.track
        }
        
        let artworkTask = ArtworkService.shared.requestDownloadArtwork(
            from: playlist.images,
            preferredWidth: 300,
            urlSession: self.urlSession
        )
        
        if let artworkTask = artworkTask {
            let downloadTask = artworkTask.0
            let identifier = artworkTask.1
            
            downloadTask.taskDescription = TaskIdentifier.artwork(playlist.id, identifier).serializeValue
            downloadTask.resume()
        }
        
        var artworkDownloadTasks: [String: URLSessionDownloadTask] = [:]
        
        for trackInfo in tracksInfo {
            guard let track = trackMaps[trackInfo.trackId] else {
                continue
            }
            
            LocalStorageManager.shared.saveTrackInfo(storageClass: .download, trackInfo: trackInfo)
            LocalStorageManager.shared.cacheTrack(track: track)
            
            let artworkTask = ArtworkService.shared.requestDownloadArtwork(
                from: track.album.images,
                preferredWidth: 300,
                urlSession: self.urlSession
            )
            
            if let artworkTask = artworkTask {
                let downloadTask = artworkTask.0
                let identifier = artworkTask.1
                
                downloadTask.taskDescription = TaskIdentifier.artwork(track.id, identifier).serializeValue
                artworkDownloadTasks[identifier] = downloadTask
            }
            
            group.enter()
            serviceProvider.resolveStorage(for: trackInfo.fileId) { result in
                switch result {
                case .success(let response):
                    let task = self.urlSession.downloadTask(with: response.url)
                    task.taskDescription = TaskIdentifier.track(track.id, trackInfo.fileId).serializeValue
                    task.resume()
                    group.leave()
                case .failure(let error):
                    NSLog("[Download] Storage resolve error: \(error)")
                    group.leave()
                }
            }
        }
        
        for task in artworkDownloadTasks.values {
            task.resume()
        }
        
        group.notify(queue: .main) {
            completion(.success(Void()))
        }
    }
}

// MARK: - Identifier

extension DownloadManager {
    
    public enum TaskIdentifier {
        case artwork(String, String)
        case track(String, String)
        
        public init?(_ value: String) {
            let components = value.components(separatedBy: "|")
            guard components.count == 3 else {
                return nil
            }
            
            let identifierType = components[0]
            let itemId = components[1]
            let resourceIdentifier = components[2]
            
            if identifierType == "artwork" {
                self = .artwork(itemId, resourceIdentifier)
            } else if identifierType == "track" {
                self = .track(itemId, resourceIdentifier)
            } else {
                return nil
            }
        }
        
        var serializeValue: String {
            switch self {
            case .artwork(let itemId, let resourceIdentifier):
                return "artwork|\(itemId)|\(resourceIdentifier)"
            case .track(let itemId, let resourceIdentifier):
                return "track|\(itemId)|\(resourceIdentifier)"
            }
        }
    }
}

extension NSNotification.Name {
    
    public static let downloadManagerTaskChanges = NSNotification.Name("DownloadManagerTaskChanges")
    public static let downloadManagerTaskProgressUpdate = NSNotification.Name("DownloadManagerTaskProgressUpdate")
}

extension DownloadManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        NotificationCenter.default.post(name: .downloadManagerTaskChanges, object: self)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let httpResponse = downloadTask.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            NSLog("[Download] Download response error, task: \(downloadTask)")
            return
        }
        
        guard let rawIdentifier = downloadTask.taskDescription, let identifier = TaskIdentifier(rawIdentifier) else {
            NSLog("[Download] Unable to resolve download task description: \(downloadTask)")
            return
        }
        
        NSLog("[Download] Task: \(downloadTask), didFinishDownloadingTo: \(location)")
        switch identifier {
        case .artwork(_, let resourceIdentifier):
            ArtworkService.shared.migrateDownloadedArtworkFile(resourceIdentifier, location: location)
        case .track(_, let resourceIdentifier):
            AudioFile.migrateDownloadedAudioFile(resourceIdentifier, fromLocation: location)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        NotificationCenter.default.post(name: .downloadManagerTaskProgressUpdate, object: downloadTask)
    }
}
