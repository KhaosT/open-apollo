//
//  SpotifyPlayer.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/13/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import ClockKit
import AudioKit
import SpotifyServices

class SpotifyPlayer {
    
    static let shared = SpotifyPlayer()
    
    let player = AudioPlayer()
    
    private var currentPlaybackId: String?
    
    private weak var activeEventProcessor: AudioPlayerEventProcessor?
    
    init() {
        player.eventProcessor = self
    }
    
    func showNowPlaying(from interfaceController: WKInterfaceController) {
        interfaceController.pushController(withName: "Now Playing", context: nil)
    }
    
    func playPlaylist(_ playlist: AnyPlaylist, from interfaceController: WKInterfaceController) {
        switch playlist {
        case let fullPlaylist as Playlist:
            playPlaylist(fullPlaylist, from: interfaceController)
        default:
            playPlaylist(playlist.id, from: interfaceController)
        }
    }
    
    func playPlaylist(_ id: String, from interfaceController: WKInterfaceController) {
        interfaceController.pushController(withName: "Now Playing", context: nil)
        
        if currentPlaybackId == id, player.playbackState != .stopped {
            return
        }
        
        currentPlaybackId = id
        
        var audioTracks: [AudioTrack]?
        var audioGranted = false
        
        let group = DispatchGroup()
        
        group.enter()
        player.prepareToPlay { granted, _ in
            audioGranted = granted
            
            guard !granted,
                let nowPlayingController = WKExtension.shared().visibleInterfaceController as? NowPlayingInterfaceController else {
                    group.leave()
                    return
            }
            
            nowPlayingController.pop()
            group.leave()
        }
        
        group.enter()
        SpotifyServiceProvider.shared.getPlaylist(id) { fullPlaylistResult in
            guard case .success(let fullPlaylist) = fullPlaylistResult else {
                group.leave()
                return
            }
            
            audioTracks = fullPlaylist.tracks.items.compactMap { SpotifyServiceProvider.shared.audioTrack(for: $0.track, offlineOnly: AppSession.shared.offline) }
            
            if UserPreferences.shuffle {
                audioTracks?.shuffle()
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard audioGranted, let audioTracks = audioTracks else {
                return
            }
            self.willStartPlayback()
            self.player.play(audioTracks, resetCurrentQueue: true)
        }
    }
    
    func playPlaylist(_ playlist: Playlist, from interfaceController: WKInterfaceController) {
        interfaceController.pushController(withName: "Now Playing", context: nil)
        
        if currentPlaybackId == playlist.id, player.playbackState != .stopped {
            return
        }
        
        currentPlaybackId = playlist.id
        
        var audioTracks = playlist.tracks.items.compactMap { SpotifyServiceProvider.shared.audioTrack(for: $0.track, offlineOnly: AppSession.shared.offline) }

        if UserPreferences.shuffle {
            audioTracks.shuffle()
        }
        
        player.prepareToPlay { granted, _ in
            guard !granted,
                let nowPlayingController = WKExtension.shared().visibleInterfaceController as? NowPlayingInterfaceController else {
                    self.willStartPlayback()
                    self.player.play(audioTracks, resetCurrentQueue: true)
                    return
            }
            
            nowPlayingController.pop()
        }
    }
    
    func playAlbum(_ album: SimplifiedAlbum, from interfaceController: WKInterfaceController) {
        interfaceController.pushController(withName: "Now Playing", context: nil)
        
        if currentPlaybackId == album.id, player.playbackState != .stopped {
            return
        }
        
        currentPlaybackId = album.id
        
        var audioTracks: [AudioTrack]?
        var audioGranted = false
        
        let group = DispatchGroup()
        
        group.enter()
        player.prepareToPlay { granted, _ in
            audioGranted = granted
            
            guard !granted,
                let nowPlayingController = WKExtension.shared().visibleInterfaceController as? NowPlayingInterfaceController else {
                    group.leave()
                    return
            }
            
            nowPlayingController.pop()
            group.leave()
        }
        
        group.enter()
        SpotifyServiceProvider.shared.getAlbum(album.id) { fullAlbumResult in
            guard case .success(let fullAlbum) = fullAlbumResult else {
                group.leave()
                return
            }
            
            audioTracks = fullAlbum.tracks.items.compactMap {
                SpotifyServiceProvider.shared.audioTrack(for: Track(simplifiedTrack: $0, album: fullAlbum), offlineOnly: AppSession.shared.offline)
            }
            
            if UserPreferences.shuffle {
                audioTracks?.shuffle()
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard audioGranted, let audioTracks = audioTracks else {
                return
            }
            self.willStartPlayback()
            self.player.play(audioTracks, resetCurrentQueue: true)
        }
    }
    
    func playTrack(_ track: Track, from interfaceController: WKInterfaceController) {
        if currentPlaybackId == track.id, player.playbackState != .stopped {
            interfaceController.pushController(withName: "Now Playing", context: nil)
            return
        }
        
        currentPlaybackId = track.id
        
        guard let audioTrack = SpotifyServiceProvider.shared.audioTrack(for: track, offlineOnly: AppSession.shared.offline) else {
            interfaceController.presentAlert(
                withTitle: "Unable To Play",
                message: "This track is not playable.",
                preferredStyle: .alert,
                actions: [
                    WKAlertAction(
                        title: "OK",
                        style: .cancel,
                        handler: {}
                    )
                ]
            )
            return
        }
        interfaceController.pushController(withName: "Now Playing", context: nil)
        
        player.prepareToPlay { grant, _ in
            guard !grant,
                let nowPlayingController = WKExtension.shared().visibleInterfaceController as? NowPlayingInterfaceController else {
                    self.willStartPlayback()
                    self.player.play(audioTrack)
                    return
            }
            
            nowPlayingController.pop()
        }
    }
    
    func registerPlayerEventProcessor(_ eventProcessor: AudioPlayerEventProcessor) {
        activeEventProcessor = eventProcessor
        
        eventProcessor.audioPlayer(player, didUpdateCurrentTrack: player.currentTrack)
        eventProcessor.audioPlayer(player, didUpdatePlaybackState: player.playbackState)
    }
    
    func unregisterPlayerEventProcessor(_ eventProcessor: AudioPlayerEventProcessor) {
        guard activeEventProcessor === eventProcessor else {
            return
        }
        activeEventProcessor = nil
    }
}

// MARK: - Playback

extension SpotifyPlayer {
    
    func willStartPlayback() {
    }
    
    func didStopPlayback() {
    }
}

// MARK: - AudioPlayerEventProcessor

extension SpotifyPlayer: AudioPlayerEventProcessor {
    
    func audioPlayer(_ player: AudioPlayer, didUpdateCurrentTrack audioTrack: AudioTrack?) {
        activeEventProcessor?.audioPlayer(player, didUpdateCurrentTrack: audioTrack)
    }
    
    func audioPlayer(_ player: AudioPlayer, didUpdatePlaybackState playbackState: PlaybackState) {
        if let activeComplications = CLKComplicationServer.sharedInstance().activeComplications, !activeComplications.isEmpty {
            for complication in activeComplications {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
            }
        }
        
        switch playbackState {
        case .stopped:
            currentPlaybackId = nil
            didStopPlayback()
        case .paused,
             .interrupted:
            didStopPlayback()
        case .loading,
             .buffering,
             .playing:
            willStartPlayback()
        }
        activeEventProcessor?.audioPlayer(player, didUpdatePlaybackState: playbackState)
    }
    
    func audioPlayer(_ player: AudioPlayer, didUpdateCurrentProgress currentProgress: Double) {
        if let activeComplications = CLKComplicationServer.sharedInstance().activeComplications, !activeComplications.isEmpty {
            for complication in activeComplications {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
            }
        }
    }
}
