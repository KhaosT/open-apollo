//
//  NowPlayingItemController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/18/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import AudioKit
import SpotifyServices

class NowPlayingItemController {
    
    var itemGroup: WKInterfaceGroup
    var animationView: WKInterfaceImage
    var imageView: WKInterfaceGroup
    var nameLabel: WKInterfaceLabel
    
    private var imageTask: URLSessionDataTask?
    private var isAnimating = false
    
    init(itemGroup: WKInterfaceGroup,
         animationView: WKInterfaceImage,
         imageView: WKInterfaceGroup,
         nameLabel: WKInterfaceLabel) {
        self.itemGroup = itemGroup
        self.animationView = animationView
        self.imageView = imageView
        self.nameLabel = nameLabel
    }
    
    deinit {
        imageTask?.cancel()
    }
    
    func updateNowPlayingContent() {
        guard SpotifyPlayer.shared.player.currentTrack != nil else {
            self.animationView.stopAnimating()
            self.animationView.setImageNamed("Playing0")
            self.itemGroup.setHidden(true)
            return
        }
        
        self.itemGroup.setHidden(false)
        
        // Animation
        switch SpotifyPlayer.shared.player.playbackState {
        case .buffering,
             .loading,
             .playing:
            if !isAnimating {
                self.isAnimating = true
                self.animationView.setImageNamed("Playing")
                self.animationView.startAnimatingWithImages(in: NSRange(0..<76), duration: 1.27, repeatCount: 0)
            }
            
        case .paused,
             .stopped,
             .interrupted:
            if isAnimating {
                self.isAnimating = false
                self.animationView.stopAnimating()
                self.animationView.setImageNamed("Playing0")
            }
        }
    }
}

extension NowPlayingItemController: AudioPlayerEventProcessor {
    
    func audioPlayer(_ player: AudioPlayer, didUpdateCurrentTrack audioTrack: AudioTrack?) {
        imageTask?.cancel()
        imageTask = nil
        
        guard let metadata = audioTrack?.metadata else {
            nameLabel.setText("No Song")
            return
        }
        
        nameLabel.setText(metadata.title ?? "Unknown")
        
        if let audioTrack = audioTrack as? SpotifyAudioTrack, !audioTrack.track.album.images.isEmpty {
            imageView.setBackgroundImage(UIImage(named: "Explore-Loading"))
            
            imageTask = ArtworkService.shared.requestArtwork(
                from: audioTrack.track.album.images,
                storageClass: .temporary,
                preferredWidth: 300,
                completion: { [weak self] image in
                    DispatchQueue.main.async {
                        self?.imageView.setBackgroundImage(image)
                    }
                }
            )
        } else {
            imageView.setBackgroundImageNamed("Playlist-Default")
        }
    }
    
    func audioPlayer(_ player: AudioPlayer, didUpdatePlaybackState playbackState: PlaybackState) {
        updateNowPlayingContent()
    }
}
