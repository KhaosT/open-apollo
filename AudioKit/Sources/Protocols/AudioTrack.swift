//
//  AudioTrack.swift
//  AudioKit
//
//  Created by Khaos Tian on 9/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import AVFoundation

public protocol AudioTrack: class {
    
    var identifier: String { get }
        
    /// true if the underlying audio track is live streaming content
    var isLive: Bool { get }
    
    /// Duration of the track, 0 if the duration is unknown
    var duration: TimeInterval { get }
        
    /// Metadata for the audio track
    var metadata: AudioTrackMetadata { get }
    
    /// Configure the audio track's event delegate
    ///
    /// - Parameter eventDelegate: AudioTrackEventDelegate
    func configure(with eventDelegate: AudioTrackEventDelegate?)
    
    /// Read audio track to buffer
    ///
    /// - Parameters:
    ///   - buffer: AVAudioPCMBuffer
    /// - Returns: AudioTrackReadResult
    /// - Throws: AudioTrackReadError
    func read(into buffer: inout AVAudioPCMBuffer?) throws -> AudioTrackReadResult
    
    /// Seek To
    ///
    /// - Parameter time: time in track
    func seekTo(time: TimeInterval)
    
    /// Prepare content
    /// For streamable content, please start loading content after the invocation.
    /// This method may get invoked proactively to preload content.
    /// This method may get invoked multiple times.
    func prepare()
    
    /// AudioPlayer is able to play the audio track
    func willStartPlayback()
    
    /// AudioPlayer pauses the playback
    func didPausePlayback()
    
    /// AudioPlayer stopped the playback
    func didStopPlayback()
    
    /// AudioPlayer finished the playback
    func didFinishPlayback()
}

public protocol AudioTrackEventDelegate: class {
    
    func audioTrack(_ audioTrack: AudioTrack, handleEvent: AudioTrackEvent)
    func audioTrack(_ audioTrack: AudioTrack, didUpdateMetadata: AudioTrackMetadata)
}

public enum AudioTrackReadResult {
    case normal
    case noFrameAvailable
    case eof
}

public enum AudioTrackReadError: Error {
    case buffering
    case endOfTrack
    case internalError
}

public enum AudioTrackEvent {
    case didFinishBuffering
    case haveAdditionalContent
    case encounteredUnrecoverableError
}
