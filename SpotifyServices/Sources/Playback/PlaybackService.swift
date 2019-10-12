//
//  StreamingService.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import UIKit

class PlaybackService: NSObject {
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 300
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = true
        
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return urlSession
    }()
    
    private var audioTrackMap: [String: SpotifyAudioTrack] = [:]
    private var taskAudioTrackMap: [URLSessionTask: SpotifyAudioTrack] = [:]
    
    private let operationQueue = DispatchQueue(label: "org.oltica.PlaybackService")
    private unowned let serviceProvider: SpotifyServiceProvider
    
    init(with serviceProvider: SpotifyServiceProvider) {
        self.serviceProvider = serviceProvider
    }
    
    func audioTrack(for track: Track, offlineOnly: Bool) -> SpotifyAudioTrack? {
        guard !track.isLocal else {
            return nil
        }
        
        if offlineOnly {
            guard let trackInfo = LocalStorageManager.shared.trackInfo(storageClass: .download, trackId: track.id), AudioFile.isLocallyAvailable(for: trackInfo) else {
                return nil
            }
        }
        
        return operationQueue.sync {
            if let audioTrack = self.audioTrackMap[track.id] {
                return audioTrack
            }
            
            let audioTrack = SpotifyAudioTrack(track, playbackService: self)
            audioTrackMap[track.id] = audioTrack
            
            return audioTrack
        }
    }
}

// MARK: - Audio File Info

extension PlaybackService {
    
    func prepareAudioTrack(_ audioTrack: SpotifyAudioTrack) {
        operationQueue.async {
            if let trackInfo = LocalStorageManager.shared.trackInfo(storageClass: .download, trackId: audioTrack.track.id) {
                audioTrack.didFinishPrepare(trackInfo)
            } else if let trackInfo = LocalStorageManager.shared.trackInfo(storageClass: .temporary, trackId: audioTrack.track.id) {
                audioTrack.didFinishPrepare(trackInfo)
            } else {
                self.serviceProvider.trackFileInfo(for: audioTrack.track.id) { trackInfoResult in
                    switch trackInfoResult {
                    case .success(let trackInfo):
                        LocalStorageManager.shared.saveTrackInfo(storageClass: .temporary, trackInfo: trackInfo)
                        audioTrack.didFinishPrepare(trackInfo)
                    case .failure(let error):
                        audioTrack.didFailPrepare(error)
                    }
                }
            }
        }
    }
    
    func loadAudioTrack(_ audioTrack: SpotifyAudioTrack, trackFileInfo: TrackFileInfo, incrementalOffset: UInt64?) {
        operationQueue.async {
            self.serviceProvider.resolveStorage(for: trackFileInfo.fileId) { storageResolveResult in
                switch storageResolveResult {
                case .success(let response):
                    var request = URLRequest(url: response.url)
                    if let incrementalOffset = incrementalOffset {
                        request.addValue("bytes=\(incrementalOffset)-", forHTTPHeaderField: "Range")
                    }
                    let task = self.urlSession.dataTask(with: request)
                    self.taskAudioTrackMap[task] = audioTrack
                    task.resume()
                    audioTrack.startLoadingAudioTrack(with: task)
                case .failure(let error):
                    audioTrack.didFailLoadingWithError(error)
                }
            }
        }
    }
    
    func invalidateAudioLoadingTask(_ task: URLSessionDataTask) {
        switch task.state {
        case .running,
             .suspended:
            task.cancel()
        case .canceling,
             .completed:
            break
        @unknown default:
            break
        }
        
        operationQueue.async {
            self.taskAudioTrackMap[task] = nil
        }
    }
}

// MARK: - Artworks

extension PlaybackService {
    
    func requestArtworkFor(_ audioTrack: SpotifyAudioTrack, preferredWidth: CGFloat, completion: @escaping (UIImage?) -> Void) {
        ArtworkService.shared.requestArtworkFor(audioTrack.track, storageClass: .temporary, preferredWidth: preferredWidth, completion: completion)
    }
    
    func cachedArtwork(for audioTrack: SpotifyAudioTrack, preferredWidth: CGFloat) -> UIImage? {
        return ArtworkService.shared.cachedArtwork(from: audioTrack.track.album.images, preferredWidth: preferredWidth)
    }
}

// MARK: - URLSessionDataDelegate

extension PlaybackService: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        operationQueue.async {
            guard let audioTrack = self.taskAudioTrackMap[task] else {
                return
            }
            
            self.taskAudioTrackMap[task] = nil
            audioTrack.handleTask(task, finishWith: error)
        }
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        operationQueue.async {
            guard let audioTrack = self.taskAudioTrackMap[dataTask] else {
                return
            }
            
            audioTrack.handleAudioLoadingResponse(response)
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        operationQueue.async {
            guard let audioTrack = self.taskAudioTrackMap[dataTask] else {
                return
            }
            
            audioTrack.handleNewData(data)
        }
    }
}
