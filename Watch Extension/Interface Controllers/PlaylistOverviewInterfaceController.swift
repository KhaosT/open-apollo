//
//  PlaylistOverviewInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import WatchKit
import SpotifyServices

class PlaylistOverviewInterfaceController: WKInterfaceController {

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var imageView: WKInterfaceImage!
    
    private var playlist: AnyPlaylist!
    private var imageTask: URLSessionDataTask?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let context = context as? SimplifiedPlaylist {
            playlist = context
            addMenuItem(withImageNamed: "Download", title: "Download", action: #selector(didTapDownload))
        } else if let context = context as? Playlist {
            playlist = context
        } else {
            fatalError()
        }
        
        configure()
    }

    @IBAction func didTapPlaylist() {
        SpotifyPlayer.shared.playPlaylist(playlist, from: self)
    }
    
    deinit {
        imageTask?.cancel()
    }
}

// MARK: - Action

extension PlaylistOverviewInterfaceController {
    
    @objc
    private func didTapDownload() {
        guard let playlist = playlist as? SimplifiedPlaylist else {
            return
        }
        
        pushController(withName: "Download Playlist", context: playlist)
    }
}

// MARK: - Configuration

extension PlaylistOverviewInterfaceController {
    
    private func configure() {
        titleLabel.setText(playlist.name)
        loadImage()
    }
    
    private func loadImage() {
        imageTask?.cancel()

        guard !playlist.images.isEmpty else {
            imageView.setImageNamed("Playlist-Default")
            return
        }

        imageView.setImageNamed("Loading")
        imageView.startAnimatingWithImages(in: NSRange(location: 0, length: 60), duration: 1.0, repeatCount: 0)
        
        imageTask = ArtworkService.shared.requestArtwork(
            from: playlist.images,
            storageClass: .temporary,
            preferredWidth: WKInterfaceDevice.current().screenBounds.width * 0.9,
            completion: { [weak self] image in
                guard let strongSelf = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    if let image = image {
                        strongSelf.imageView.setImage(image)
                    } else {
                        strongSelf.imageView.setImageNamed("Playlist-Default")
                    }
                }
            }
        )
    }
}
