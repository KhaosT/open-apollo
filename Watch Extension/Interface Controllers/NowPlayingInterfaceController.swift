//
//  NowPlayingInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/14/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import AudioKit
import SpotifyServices

class NowPlayingInterfaceController: WKInterfaceController {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var subtitleLabel: WKInterfaceLabel!
    
    @IBOutlet weak var playPauseButton: WKInterfaceButton!
    
    override func willActivate() {
        super.willActivate()
        SpotifyPlayer.shared.registerPlayerEventProcessor(self)
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        SpotifyPlayer.shared.unregisterPlayerEventProcessor(self)
    }
    
    @IBAction func didTapPlayPauseButton() {
        WKInterfaceDevice.current().play(.click)
        SpotifyPlayer.shared.player.togglePlayback()
    }
    
    @IBAction func didTapPrevious() {
        WKInterfaceDevice.current().play(.click)
        SpotifyPlayer.shared.player.previousTrack()
    }
    
    @IBAction func didTapNext() {
        WKInterfaceDevice.current().play(.click)
        SpotifyPlayer.shared.player.nextTrack()
    }
    
}

extension NowPlayingInterfaceController: AudioPlayerEventProcessor {
    
    func audioPlayer(_ player: AudioPlayer, didUpdateCurrentTrack audioTrack: AudioTrack?) {
        guard let metadata = audioTrack?.metadata else {
            titleLabel.setText("No Song")
            subtitleLabel.setHidden(true)
            return
        }
        
        titleLabel.setText(metadata.title ?? "Unknown")
        
        if let artist = metadata.artist {
            subtitleLabel.setHidden(false)
            subtitleLabel.setText(artist)
        } else if let albumTitle = metadata.albumTitle {
            subtitleLabel.setHidden(false)
            subtitleLabel.setText(albumTitle)
        } else {
            subtitleLabel.setHidden(true)
        }
    }
    
    func audioPlayer(_ player: AudioPlayer, didUpdatePlaybackState playbackState: PlaybackState) {
        switch playbackState {
        case .loading:
            titleLabel.setText("Loading…")
            subtitleLabel.setHidden(true)
            playPauseButton.setBackgroundImageNamed("Pause")
        case .buffering:
            subtitleLabel.setHidden(false)
            subtitleLabel.setText("Loading…")
            playPauseButton.setBackgroundImageNamed("Pause")
        case .playing:
            audioPlayer(player, didUpdateCurrentTrack: player.currentTrack)
            playPauseButton.setBackgroundImageNamed("Pause")
        case .paused:
            audioPlayer(player, didUpdateCurrentTrack: player.currentTrack)
            playPauseButton.setBackgroundImageNamed("Play")
        case .stopped:
            audioPlayer(player, didUpdateCurrentTrack: player.currentTrack)
            playPauseButton.setBackgroundImageNamed("Play")
        case .interrupted:
            playPauseButton.setBackgroundImageNamed("Play")
        }
    }
}
