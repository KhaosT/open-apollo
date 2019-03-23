//
//  AudioPlayerEventProcessor.swift
//  Apollo
//
//  Created by Khaos Tian on 10/18/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public protocol AudioPlayerEventProcessor: class {
    func audioPlayer(_ player: AudioPlayer, didUpdateCurrentTrack audioTrack: AudioTrack?)
    func audioPlayer(_ player: AudioPlayer, didUpdatePlaybackState playbackState: PlaybackState)
    func audioPlayer(_ player: AudioPlayer, didUpdateCurrentProgress currentProgress: Double)
}

extension AudioPlayerEventProcessor {
    
    public func audioPlayer(_ player: AudioPlayer, didUpdateCurrentProgress currentProgress: Double) {}
}
