//
//  SpotifyAudioTrack.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit
import MediaPlayer

public class SpotifyAudioTrack {
    
    private var audioFile: AudioFile?
    private var decoder: VorbisDecoder?
    public let track: Track
    
    public var metadata = AudioTrackMetadata()
    
    private var isPreparing = false
    private var trackFileInfo: TrackFileInfo?
    
    private unowned let playbackService: PlaybackService
    private weak var eventDelegate: AudioTrackEventDelegate?
    
    private weak var dataTask: URLSessionDataTask?
    private var hasRetried = false
    
    init(_ track: Track, playbackService: PlaybackService) {
        self.track = track
        self.playbackService = playbackService
        
        self.metadata.title = track.name
        self.metadata.artist = track.artists.map { $0.name }.joined(separator: ", ")
        self.metadata.albumTitle = track.album.name
        self.metadata.albumArtist = track.album.artists.map { $0.name }.joined(separator: ", ")
        self.metadata.duration = duration
    }
}

extension SpotifyAudioTrack: AudioTrack {
    
    public var identifier: String {
        return track.id
    }
    
    public var isLive: Bool {
        return false
    }
    
    public var duration: TimeInterval {
        return TimeInterval(track.durationMs) / 1000
    }
    
    public func configure(with eventDelegate: AudioTrackEventDelegate?) {
        self.eventDelegate = eventDelegate
    }
    
    public func read(into buffer: inout AVAudioPCMBuffer?) throws -> AudioTrackReadResult {
        guard let decoder = decoder else {
            throw AudioTrackReadError.buffering
        }
        
        do {
            let result = try decoder.read(into: &buffer)
            switch result {
            case .eof:
                return .eof
            case .noFrameAvailable:
                return .noFrameAvailable
            case .normal:
                return .normal
            }
        } catch {
            guard let decoderError = error as? VorbisDecoder.Error else {
                throw error
            }
            
            switch decoderError {
            case .notEnoughBuffer:
                throw AudioTrackReadError.buffering
            case .internalError:
                throw AudioTrackReadError.internalError
            }
        }
    }
    
    public func seekTo(time: TimeInterval) {
        guard time == 0 else {
            return
        }
        
        audioFile?.resetAudioFileReadProgress()
    }
    
    public func prepare() {
        guard trackFileInfo == nil,
            !isPreparing else {
                return
        }
        
        isPreparing = true
        playbackService.prepareAudioTrack(self)
        playbackService.requestArtworkFor(self, preferredWidth: Constants.preferredArtworkWidth) { [weak self] optionalImage in
            guard let image = optionalImage, let strongSelf = self else {
                return
            }
            
            strongSelf.metadata.artwork = MPMediaItemArtwork(
                boundsSize: image.size,
                requestHandler: { [unowned strongSelf] size -> UIImage in
                    return strongSelf.playbackService.cachedArtwork(
                        for: strongSelf,
                        preferredWidth: Constants.preferredArtworkWidth
                    )!
                    .resize(size: size)!
                }
            )
            strongSelf.eventDelegate?.audioTrack(strongSelf, didUpdateMetadata: strongSelf.metadata)
        }
    }
    
    public func willStartPlayback() {
        audioFile?.resetAudioFileReadProgress()
    }
    
    public func didPausePlayback() {
        
    }
    
    public func didStopPlayback() {
        
    }
    
    public func didFinishPlayback() {
        self.isPreparing = false
        self.hasRetried = false
        
        if let dataTask = self.dataTask {
            self.playbackService.invalidateAudioLoadingTask(dataTask)
        }
        
        self.trackFileInfo = nil
        self.audioFile = nil
        self.decoder = nil
    }
}

// MARK: - Streaming Handling

extension SpotifyAudioTrack {
    
    func didFinishPrepare(_ trackFileInfo: TrackFileInfo) {
        self.trackFileInfo = trackFileInfo
        
        if let trackKey = KeychainServices.shared.decrypt(trackFileInfo.trackKeyData) {
            let optionalAudioFile = AudioFile(
                AudioFile.storageLocation(for: trackFileInfo),
                fileInfo: trackFileInfo,
                audioKeyData: trackKey
            )
            
            guard let audioFile = optionalAudioFile else {
                log("An error has occurred while trying to play \"\(track.name)\".\n\nThe encryption key might be wrong for the audio file.")
                NSLog("AudioFile Creation Error")
                return
            }
            
            self.audioFile = audioFile
            self.decoder = VorbisDecoder(audioFile: audioFile)
            
            if audioFile.isCompleted {
                self.decoder?.dataSourceDidFinishLoading()
                self.eventDelegate?.audioTrack(self, handleEvent: .haveAdditionalContent)
            } else {
                self.playbackService.loadAudioTrack(self, trackFileInfo: trackFileInfo, incrementalOffset: audioFile.availableLength)
            }
        } else {
            // TODO: handle error
            self.eventDelegate?.audioTrack(self, handleEvent: .encounteredUnrecoverableError)
            log("An error has occurred while trying to play \"\(track.name)\".\n\nUnable to locate encryption key for the audio file.")
            NSLog("Audio Track Key Unwrap Error")
        }
        
        self.isPreparing = false
    }
    
    func didFailPrepare(_ error: Error) {
        if hasRetried {
            isPreparing = false
            log("An error has occurred while trying to play \"\(track.name)\".\n\nUnable to prepare audio file. \(error.localizedDescription)")
        } else {
            hasRetried = true
            playbackService.prepareAudioTrack(self)
        }
    }
    
    func startLoadingAudioTrack(with task: URLSessionDataTask) {
        self.dataTask = task
    }
    
    func didFailLoadingWithError(_ error: Error) {
        if let audioFile = audioFile, let trackFileInfo = trackFileInfo, !hasRetried, !audioFile.isCompleted {
            hasRetried = true
            playbackService.loadAudioTrack(self, trackFileInfo: trackFileInfo, incrementalOffset: audioFile.availableLength)
        } else {
            log("An error has occurred while trying to play \"\(track.name)\".\n\nUnable to stream audio file. \(error.localizedDescription)")
        }
    }
    
    func handleAudioLoadingResponse(_ response: URLResponse) {
        let contentLength = response.expectedContentLength
        guard let httpResponse = response as? HTTPURLResponse, contentLength > 0 else {
            return
        }
        
        audioFile?.updateExpectedLength(UInt64(contentLength), isIncremental: httpResponse.statusCode == 206)
    }
    
    func handleNewData(_ data: Data) {
        audioFile?.write(data)
        decoder?.handleAudioFileUpdate()
        eventDelegate?.audioTrack(self, handleEvent: .haveAdditionalContent)
    }
    
    func handleTask(_ task: URLSessionTask, finishWith error: Error?) {
        if let error = error {
            if let audioFile = audioFile, let trackFileInfo = trackFileInfo, !hasRetried, !audioFile.isCompleted {
                hasRetried = true
                playbackService.loadAudioTrack(self, trackFileInfo: trackFileInfo, incrementalOffset: audioFile.availableLength)
            } else {
                eventDelegate?.audioTrack(self, handleEvent: .encounteredUnrecoverableError)
                log("An error has occurred while trying to play \"\(track.name)\".\n\nUnable to stream audio file. \(error.localizedDescription)")
                NSLog("Streaming Error: \(error.localizedDescription)")
            }
        } else {
            NSLog("Finished Loading")
            audioFile?.finalizeFile()
            decoder?.dataSourceDidFinishLoading()
            eventDelegate?.audioTrack(self, handleEvent: .didFinishBuffering)
        }
    }
}

// MARK: - Constants

extension SpotifyAudioTrack {
    
    private struct Constants {
        static let preferredArtworkWidth: CGFloat = 300
    }
}
