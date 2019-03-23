//
//  PlaylistDualItemController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class PlaylistDualItemController: NSObject {

    @IBOutlet weak var leftContainer: WKInterfaceButton!
    @IBOutlet weak var leftImage: WKInterfaceImage!
    
    @IBOutlet weak var rightContainer: WKInterfaceButton!
    @IBOutlet weak var rightImage: WKInterfaceImage!
    
    private var leftPlaylist: SimplifiedPlaylist?
    private var rightPlaylist: SimplifiedPlaylist?
    private var selectionHandler: ((SimplifiedPlaylist) -> Void)?
    
    private var leftImageTask: URLSessionDataTask?
    private var rightImageTask: URLSessionDataTask?
    
    deinit {
        leftImageTask?.cancel()
        rightImageTask?.cancel()
    }

    func configure(_ playlists: [SimplifiedPlaylist],
                   selectionHandler: @escaping (SimplifiedPlaylist) -> Void) {
        guard playlists.count <= 2 else {
            fatalError()
        }
        
        self.selectionHandler = selectionHandler
        
        if playlists.count == 2 {
            leftPlaylist = playlists.first
            rightPlaylist = playlists.last
            
            rightContainer.setHidden(false)
        } else {
            leftPlaylist = playlists.first
            rightPlaylist = nil
            
            rightContainer.setHidden(true)
        }
        
        loadImages()
    }
    
    @IBAction func didTapLeftContainer() {
        guard let playlist = leftPlaylist else {
            return
        }
        selectionHandler?(playlist)
    }
    
    @IBAction func didTapRightContainer() {
        guard let playlist = rightPlaylist else {
            return
        }
        selectionHandler?(playlist)
    }
}

// MARK: - Image

extension PlaylistDualItemController {
    
    private func loadImages() {
        if let playlist = leftPlaylist {
            leftImage.setImage(Constants.defaultImage)
            
            leftImageTask = ArtworkService.shared.requestArtwork(
                from: playlist.images,
                storageClass: .temporary,
                preferredWidth: Constants.imageWidth,
                completion: { [weak self] image in
                    guard let strongSelf = self, let image = image else {
                        return
                    }
                    
                    let resizedImage = image.resize(maxLength: Constants.imageWidth)
                    DispatchQueue.main.async {
                        strongSelf.leftImage.setImage(resizedImage)
                    }
                }
            )
        }
        
        if let playlist = rightPlaylist {
            rightImage.setImage(Constants.defaultImage)
            
            rightImageTask = ArtworkService.shared.requestArtwork(
                from: playlist.images,
                storageClass: .temporary,
                preferredWidth: Constants.imageWidth,
                completion: { [weak self] image in
                    guard let strongSelf = self, let image = image else {
                        return
                    }
                    
                    let resizedImage = image.resize(maxLength: Constants.imageWidth)
                    DispatchQueue.main.async {
                        strongSelf.rightImage.setImage(resizedImage)
                    }
                }
            )
        }
    }
}

// MARK: - Constants

extension PlaylistDualItemController {
    
    private struct Constants {
        static let imageWidth = (WKInterfaceDevice.current().screenBounds.width - 2) * 0.5
        static let defaultImage = UIImage(named: "Explore-Loading")?.resize(maxLength: Constants.imageWidth)
    }
}
