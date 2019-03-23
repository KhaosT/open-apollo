//
//  SearchResultRowController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class SearchResultRowController: NSObject {
    
    @IBOutlet weak var imageContainer: WKInterfaceGroup!
    @IBOutlet weak var image: WKInterfaceImage!
    
    @IBOutlet weak var primaryLabel: WKInterfaceLabel!
    @IBOutlet weak var secondaryLabel: WKInterfaceLabel!
    
    private var imageTask: URLSessionDataTask?
    
    deinit {
        imageTask?.cancel()
    }
}

// MARK: - Configure

extension SearchResultRowController {
    
    func configure(with track: Track) {
        primaryLabel.setText(track.name)
        
        var secondaryText = track.album.name
        
        if track.name == secondaryText, let artist = track.artists.first {
            secondaryText = artist.name
        }
        
        if let releaseYear = track.album.releaseYear {
            secondaryLabel.setText("\(secondaryText)\n\(releaseYear)")
        } else {
            secondaryLabel.setText("\(secondaryText)")
        }
        
        if !track.album.images.isEmpty {
            loadImage(track.album.images)
        } else {
            imageContainer.setHidden(true)
        }
    }
    
    func configure(with artist: Artist) {
        primaryLabel.setText(artist.name)
        secondaryLabel.setText("\(artist.followers.total.shortText) Followers")
        
        if !artist.images.isEmpty {
            loadImage(artist.images)
        } else {
            imageContainer.setHidden(true)
        }
    }
}

// MARK: - Helper

extension SearchResultRowController {
    
    private func loadImage(_ images: [Image]) {
        imageContainer.setHidden(false)
        image.setImage(Constants.defaultImage)
        
        imageTask = ArtworkService.shared.requestArtwork(
            from: images,
            storageClass: .temporary,
            preferredWidth: Constants.imageWidth,
            completion: { [weak self] image in
                guard let strongSelf = self, let image = image else {
                    return
                }
                
                let resizedImage = image.resize(maxLength: Constants.imageWidth)
                DispatchQueue.main.async {
                    strongSelf.image.setImage(resizedImage)
                }
            }
        )
    }
}

// MARK: - Constants

extension SearchResultRowController {
    
    private struct Constants {
        static let imageWidth: CGFloat = 32
        static let defaultImage = UIImage(named: "Explore-Loading")?.resize(maxLength: Constants.imageWidth)
    }
}
