//
//  ArtistDetailInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class ArtistDetailInterfaceController: WKInterfaceController {

    private var artist: Artist!
    
    @IBOutlet weak var loadingIndicator: WKInterfaceImage!
    @IBOutlet weak var noResultLabel: WKInterfaceLabel!
    @IBOutlet weak var resultTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let context = context as? Artist else {
            fatalError()
        }
        
        artist = context
        setTitle(artist.name)
        
        loadAlbums()
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}

// MARK: - Action

extension ArtistDetailInterfaceController {
    
    private func didSelectAlbum(_ album: SimplifiedAlbum) {
        SpotifyPlayer.shared.playAlbum(album, from: self)
    }
}

// MARK: - Album

extension ArtistDetailInterfaceController {
    
    private func loadAlbums() {
        SpotifyServiceProvider.shared.getArtistAlbums(artist.id) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    strongSelf.updateAlbums(response.items)
                }
            case .failure:
                DispatchQueue.main.async {
                    strongSelf.pop()
                }
            }
        }
    }
    
    private func updateAlbums(_ albums: [SimplifiedAlbum]) {
        loadingIndicator.stopAnimating()
        loadingIndicator.setHidden(true)
        
        var rows: [RowContent] = []
        
        if !albums.isEmpty {
            let chunkedAlbums = albums.chunked(into: 2)
            rows.append(contentsOf: chunkedAlbums.map { .albumsTuple($0) })
        }
        
        guard !rows.isEmpty else {
            noResultLabel.setHidden(false)
            return
        }
        
        resultTable.setRowTypes(rows.map { $0.rowType })
        
        for (idx, rowContent) in rows.enumerated() {
            switch rowContent {
            case .albumsTuple(let albums):
                let controller = resultTable.rowController(at: idx) as! AlbumDualItemController
                controller.configure(albums) { [weak self] album in
                    self?.didSelectAlbum(album)
                }
            }
        }
        
        resultTable.setHidden(false)
    }
}

// MARK: - Enum

extension ArtistDetailInterfaceController {
    
    enum RowContent {
        case albumsTuple([SimplifiedAlbum])
        
        var rowType: String {
            switch self {
            case .albumsTuple:
                return "album"
            }
        }
    }
}
