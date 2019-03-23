//
//  AlbumDualItemController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class AlbumDualItemController: NSObject {
    
    @IBOutlet weak var leftContainer: WKInterfaceButton!
    @IBOutlet weak var leftImage: WKInterfaceImage!
    
    @IBOutlet weak var rightContainer: WKInterfaceButton!
    @IBOutlet weak var rightImage: WKInterfaceImage!
    
    private var leftAlbum: SimplifiedAlbum?
    private var rightAlbum: SimplifiedAlbum?
    private var selectionHandler: ((SimplifiedAlbum) -> Void)?
    
    private var leftImageTask: URLSessionDataTask?
    private var rightImageTask: URLSessionDataTask?
    
    deinit {
        leftImageTask?.cancel()
        rightImageTask?.cancel()
    }
    
    func configure(_ albums: [SimplifiedAlbum],
                   selectionHandler: @escaping (SimplifiedAlbum) -> Void) {
        guard albums.count <= 2 else {
            fatalError()
        }
        
        self.selectionHandler = selectionHandler
        
        if albums.count == 2 {
            leftAlbum = albums.first
            rightAlbum = albums.last
            
            rightContainer.setHidden(false)
        } else {
            leftAlbum = albums.first
            rightAlbum = nil
            
            rightContainer.setHidden(true)
        }
        
        loadImages()
    }
    
    @IBAction func didTapLeftContainer() {
        guard let album = leftAlbum else {
            return
        }
        selectionHandler?(album)
    }
    
    @IBAction func didTapRightContainer() {
        guard let album = rightAlbum else {
            return
        }
        selectionHandler?(album)
    }
}

// MARK: - Image

extension AlbumDualItemController {
    
    private func loadImages() {
        if let album = leftAlbum {
            leftImage.setImage(Constants.defaultImage)
            
            leftImageTask = ArtworkService.shared.requestArtwork(
                from: album.images,
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
        
        if let album = rightAlbum {
            rightImage.setImage(Constants.defaultImage)
            
            rightImageTask = ArtworkService.shared.requestArtwork(
                from: album.images,
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

extension AlbumDualItemController {
    
    private struct Constants {
        static let imageWidth = (WKInterfaceDevice.current().screenBounds.width - 2) * 0.5
        static let defaultImage = UIImage(named: "Explore-Loading")?.resize(maxLength: Constants.imageWidth)
    }
}
