//
//  AudioPlayer.swift
//  AudioKit
//
//  Created by Khaos Tian on 9/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public class AudioPlayer {
    
    private let audioSessionEventHandler = AudioSessionNotificationHandler()
    private let operationQueue = DispatchQueue(label: "app.awas.AudioPlayer.operationQueue")
    
    private var audioSessionState: AudioSessionState = .inactive
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private var cachedPlayerElapsedPlaybackTime: Double?
    
    public weak var eventProcessor: AudioPlayerEventProcessor? {
        didSet {
            guard oldValue !== eventProcessor, let eventProcessor = eventProcessor else {
                return
            }
            
            eventProcessor.audioPlayer(self, didUpdateCurrentTrack: currentTrack)
            eventProcessor.audioPlayer(self, didUpdatePlaybackState: playbackState)
        }
    }
    
    public private(set) var playbackState: PlaybackState = .stopped {
        didSet {
            guard oldValue != playbackState else {
                return
            }
            
            updateNowPlaying()
            
            guard let eventProcessor = eventProcessor else {
                return
            }
            
            DispatchQueue.main.async {
                eventProcessor.audioPlayer(self, didUpdatePlaybackState: self.playbackState)
            }
        }
    }
    
    public var currentTime: Double {
        if let currentTime = playerElapsedPlaybackTime() {
            return currentTime
        } else if let currentTime = cachedPlayerElapsedPlaybackTime {
            return currentTime
        } else {
            return 0
        }
    }
    
    public var progress: Double {
        guard let currentTrack = currentTrack, currentTrack.duration > 0 else {
            return 0
        }
        
        if let currentTime = playerElapsedPlaybackTime() {
            return min(max(0, currentTime / currentTrack.duration), 1)
        } else if let currentTime = cachedPlayerElapsedPlaybackTime {
            return min(max(0, currentTime / currentTrack.duration), 1)
        } else {
            return 0
        }
    }
    
    public private(set) var currentTrack: AudioTrack? {
        didSet {
            updateNowPlaying()
            
            guard let eventProcessor = eventProcessor else {
                return
            }
            
            DispatchQueue.main.async {
                eventProcessor.audioPlayer(self, didUpdateCurrentTrack: self.currentTrack)
            }
        }
    }
    
    private var currentTrackIndex: Int = 0
    public private(set) var queue: [AudioTrack] = []
    
    private var activeBuffers = 0
    private var isPlayerNodePlaying: Bool {
        get {
            return self.playerNode?.isPlaying ?? false
        }
    }
    
    public init() {
        setupAudioSessionEventHandler()
        configureRemoteCommands()
    }
}

// MARK: - Playback Control

extension AudioPlayer {
    
    public func prepareToPlay(_ completionHandler: @escaping ((Bool, Error?) -> Void)) {
        operationQueue.async {
            self.playerNode?.stop()
            self.audioEngine?.stop()
            
            self.playerNode = nil
            self.audioEngine = nil
            self.currentTrack = nil
            self.queue = []
            
            self.playbackState = .loading
            self.activateAudioSessionForPlayback(completionHandler)
        }
    }
    
    public func play(_ audioTrack: AudioTrack) {
        play(
            [audioTrack],
            resetCurrentQueue: true
        )
    }
    
    public func stop() {
        operationQueue.async {
            self.playerNode?.stop()
            self.audioEngine?.stop()
            
            self.playbackState = .stopped
            self.cachedPlayerElapsedPlaybackTime = nil
            self.playerNode = nil
            self.audioEngine = nil
            self.currentTrack = nil
            self.queue = []
            
            self.deactivateAudioSession()
        }
    }
    
    public func resume() {
        operationQueue.async {
            guard !self.isPlayerNodePlaying, self.playbackState == .paused, self.currentTrack != nil else {
                return
            }
            
            self.activateAudioSessionForPlayback { granted, _ in
                guard granted else {
                    return
                }
                
                try? self.audioEngine?.start()
                self.playerNode?.play()
                
                self.playbackState = .playing
            }
        }
    }
    
    public func pause() {
        operationQueue.async {
            self.cachedPlayerElapsedPlaybackTime = self.playerElapsedPlaybackTime()
            self.playerNode?.pause()
            self.audioEngine?.pause()
            
            self.playbackState = .paused
        }
    }
    
    public func togglePlayback() {
        switch playbackState {
        case .loading,
             .buffering,
             .playing:
            pause()
        case .paused:
            resume()
        case .interrupted,
             .stopped:
            break
        }
    }
    
    public func nextTrack() {
        operationQueue.async {
            self.playNextTrackInQueue()
        }
    }
    
    public func previousTrack() {
        operationQueue.async {
            guard let currentTrack = self.currentTrack, let elapsedPlaybackTime = self.playerElapsedPlaybackTime() else {
                return
            }
            
            let previousTrackIndex = self.currentTrackIndex - 1
            
            if elapsedPlaybackTime < 5, !self.queue.isEmpty, previousTrackIndex >= 0 {
                let track = self.queue[previousTrackIndex]
                self.currentTrackIndex = previousTrackIndex
                self.startPlaying(track)
            } else {
                self.startPlaying(currentTrack)
            }
        }
    }
    
    public func seekTo(_ time: TimeInterval) {
        // TODO: implement this
        fatalError("Not Implemented")
    }
}

// MARK: - Queue

extension AudioPlayer {
    
    public func play(_ audioTracks: [AudioTrack], resetCurrentQueue: Bool) {
        for audioTrack in audioTracks {
            audioTrack.configure(with: self)
        }
        
        operationQueue.async {
            if resetCurrentQueue {
                self.queue = audioTracks
                self.currentTrackIndex = 0
            } else {
                self.queue += audioTracks
            }
            
            guard !self.isPlayerNodePlaying else {
                if resetCurrentQueue {
                    if let firstTrack = audioTracks.first {
                        self.startPlaying(firstTrack)
                    } else {
                        self.stop()
                    }
                }
                
                return
            }
            
            if resetCurrentQueue, audioTracks.first == nil {
                self.stop()
                return
            }
            
            if resetCurrentQueue, let firstTrack = audioTracks.first {
                self.startPlaying(firstTrack)
            }
        }
    }
    
    public func resetQueue(stopCurrent: Bool) {
        operationQueue.async {
            if !stopCurrent, let currentTrack = self.currentTrack {
                self.queue = [currentTrack]
            } else {
                self.stop()
            }
        }
    }
    
    public func appendTrackToQueue(_ audioTrack: AudioTrack) {
        operationQueue.async {
            self.queue.append(audioTrack)
        }
    }
    
    public func playNext(_ audioTrack: AudioTrack) {
        operationQueue.async {
            if let currentTrack = self.currentTrack, let index = self.queue.firstIndex(where: { $0 === currentTrack }) {
                self.queue.insert(audioTrack, at: index.advanced(by: 1))
            } else {
                self.queue.append(audioTrack)
            }
            
            audioTrack.prepare()
        }
    }
}

// MARK: - Playback Internal

extension AudioPlayer {
    
    private var nextTrackInQueue: AudioTrack? {
        guard currentTrack != nil else {
            return nil
        }
        
        let nextIndex = currentTrackIndex + 1
        guard nextIndex < queue.count else {
            return nil
        }
        
        return queue[nextIndex]
    }
    
    private func startPlaying(_ audioTrack: AudioTrack) {
        playerNode?.stop()
        currentTrack?.didFinishPlayback()
        cachedPlayerElapsedPlaybackTime = nil

        currentTrack = audioTrack
        playbackState = .buffering
        audioTrack.prepare()
        audioTrack.willStartPlayback()

        self.activateAudioSessionForPlayback { [weak self] activated, error in
            guard let strongSelf = self else {
                return
            }
            
            if activated {
                if strongSelf.audioEngine == nil {
                    strongSelf.setupAudioEngine()
                }
                
                try? strongSelf.audioEngine!.start()
                strongSelf.playerNode!.play()
                
                strongSelf.scheduleBuffers()
            } else {
                // TODO: surface error
                strongSelf.pause()
            }
        }
    }
    
    private func scheduleBuffers() {
        for _ in 0 ..< Constants.numberOfBuffers - activeBuffers {
            readBuffer()
        }
    }
    
    private func didReachEndOfTrack() {
        guard activeBuffers == 0 else {
            return
        }
        
        playNextTrackInQueue()
    }
    
    private func readBuffer() {
        guard let track = currentTrack else {
            return
        }
        
        var buffer: AVAudioPCMBuffer?
        
        do {
            let result = try track.read(into: &buffer)
            
            switch result {
            case .normal:
                break
            case .eof:
                operationQueue.async {
                    self.didReachEndOfTrack()
                }
            case .noFrameAvailable:
                break
            }
            
            guard let buffer = buffer else {
                playbackState = .buffering
                // TODO: Schedule Next
                return
            }
            
            activeBuffers += 1
            playbackState = .playing

            playerNode!.scheduleBuffer(buffer) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.operationQueue.async {
                    strongSelf.eventProcessor?.audioPlayer(strongSelf, didUpdateCurrentProgress: strongSelf.progress)
                    strongSelf.activeBuffers -= 1
                    strongSelf.readBuffer()
                }
            }
        } catch {
            guard let readError = error as? AudioTrackReadError else {
                NSLog("Unknown Error when read: \(error)")
                return
            }
            
            switch readError {
            case .buffering:
                // TODO: Emit Loading Message
                playbackState = .buffering
                break
            case .endOfTrack:
                // TODO: Jump to next track
                break
            case .internalError:
                // TODO: Retry or skip
                break
            }
        }
    }
}

// MARK: - Remote Command

extension AudioPlayer {
    
    private func configureRemoteCommands() {
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let strongSelf = self else {
                return .noActionableNowPlayingItem
            }
            strongSelf.togglePlayback()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard self?.currentTrack != nil else {
                return .noActionableNowPlayingItem
            }
            self?.resume()
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            self?.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            self?.nextTrack()
            return .success
        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            self?.previousTrack()
            return .success
        }
    }
}

// MARK: - Audio Track Event Handling

extension AudioPlayer: AudioTrackEventDelegate {
    
    public func audioTrack(_ audioTrack: AudioTrack, handleEvent event: AudioTrackEvent) {
        switch event {
        case .haveAdditionalContent:
            guard audioTrack === currentTrack else {
                return
            }
            
            self.operationQueue.async {
                self.scheduleBuffers()
            }
        case .didFinishBuffering:
            if let indexOfTrack = queue.firstIndex(where: { $0.identifier == audioTrack.identifier }) {
                let nextTrackIndex = max(currentTrackIndex + 1, indexOfTrack + 1)
                guard nextTrackIndex - currentTrackIndex < 3, nextTrackIndex < queue.count else {
                    return
                }
                queue[nextTrackIndex].prepare()
            }
        case .encounteredUnrecoverableError:
            guard audioTrack === currentTrack else {
                return
            }
            
            nextTrack()
            break
        }
    }
    
    public func audioTrack(_ audioTrack: AudioTrack, didUpdateMetadata: AudioTrackMetadata) {
        guard audioTrack === currentTrack else {
            return
        }
        
        updateNowPlaying()
    }
}

// MARK: - Now Playing

extension AudioPlayer {
    
    private func updateNowPlaying() {
        var nowPlayingInfo = currentTrack?.metadata.nowPlayingInfo
        
        if currentTrack != nil,
            let playerNode = playerNode,
            let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            let currentTime = Double(playerTime.sampleTime) / Double(playerTime.sampleRate)
            nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
        } else {
            nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = cachedPlayerElapsedPlaybackTime ?? 0
            nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        if #available(iOS 13.0, watchOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = {
                switch playbackState {
                case .loading,
                     .buffering:
                    return .playing
                case .playing:
                    return .playing
                case .paused:
                    return .paused
                case .stopped:
                    return .stopped
                case .interrupted:
                    return .interrupted
                }
            }()
        }
    }
    
    private func playerElapsedPlaybackTime() -> Double? {
        guard currentTrack != nil,
            let playerNode = playerNode,
            let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
                return nil
        }
        
        let currentTime = Double(playerTime.sampleTime) / Double(playerTime.sampleRate)
        return currentTime
    }
}

// MARK: - Audio Session

extension AudioPlayer {
    
    private func activateAudioSessionForPlayback(_ completionHandler: @escaping ((Bool, Error?) -> Void)) {
        guard audioSessionState == .inactive else {
            completionHandler(audioSessionState == .active, nil)
            return
        }
        
        audioSessionState = .activating
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, policy: .longForm, options: [])
            #if os(watchOS) && !targetEnvironment(simulator)
            session.activate(options: []) { [weak self] activated, error in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.operationQueue.async {
                    strongSelf.audioSessionState = activated ? .active : .inactive
                    if !activated {
                        strongSelf.playbackState = .stopped
                    }
                    completionHandler(activated, error)
                }
            }
            #else
            try session.setActive(true, options: [])
            audioSessionState = .active
            completionHandler(true, nil)
            #endif
        } catch {
            playbackState = .stopped
            completionHandler(false, error)
        }
    }
    
    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [])
        audioSessionState = .inactive
    }
    
    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
        } catch {
            NSLog("Failed to start engine, error: \(error)")
        }
        
        self.audioEngine = engine
        self.playerNode = playerNode
    }
    
    private func playNextTrackInQueue() {
        playerNode?.stop()

        guard let nextTrackInQueue = nextTrackInQueue else {
            stop()
            return
        }
        
        currentTrackIndex += 1
        startPlaying(nextTrackInQueue)
        self.nextTrackInQueue?.prepare()
    }
}

// MARK: - Audio Session Event Handling

extension AudioPlayer {
    
    private func setupAudioSessionEventHandler() {
        audioSessionEventHandler.interruptionBeganHandler = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.operationQueue.async {
                strongSelf.handleInterruptionBegan()
            }
        }
        
        audioSessionEventHandler.interruptionEndedHandler = { [weak self] interruptionOptions in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.operationQueue.async {
                strongSelf.handleInterruptionEnded(interruptionOptions)
            }
        }
        
        audioSessionEventHandler.routeChangeHandler = { [weak self] reason, userInfo in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.operationQueue.async {
                strongSelf.handleRouteChange(reason, userInfo: userInfo)
            }
        }
        
        audioSessionEventHandler.mediaServicesResetHandler = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.operationQueue.async {
                strongSelf.handleMediaServiceReset()
            }
        }
    }
    
    private func handleInterruptionBegan() {
        pause()
        audioSessionState = .inactive
    }
    
    private func handleInterruptionEnded(_ options: AVAudioSession.InterruptionOptions) {
        audioSessionState = .inactive
        
        if options.contains(.shouldResume) {
            resume()
        }
    }
    
    private func handleRouteChange(_ reason: AVAudioSession.RouteChangeReason, userInfo: [AnyHashable: Any]) {
        
    }
    
    private func handleMediaServiceReset() {
        audioSessionState = .inactive
        stop()
    }
}

// MARK: - Constants

extension AudioPlayer {
    
    private struct Constants {
        static let numberOfBuffers = 16
    }
}
