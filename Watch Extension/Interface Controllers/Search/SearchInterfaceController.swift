//
//  SearchInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import WatchKit
import SpotifyServices

class SearchInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var loadingIndicator: WKInterfaceImage!
    @IBOutlet weak var noResultLabel: WKInterfaceLabel!
    @IBOutlet weak var resultTable: WKInterfaceTable!
    
    private var rows: [RowContent] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let keyword = context as? String else {
            return
        }
        
        performSearch(with: keyword)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let rowContent = rows[rowIndex]
        switch rowContent {
        case .track(let track):
            didSelectTrack(track)
        case .artist(let artist):
            didSelectArtist(artist)
        default:
            break
        }
    }
}

// MARK: - Action

extension SearchInterfaceController {
    
    private func didSelectTrack(_ track: Track) {
        SpotifyPlayer.shared.playTrack(track, from: self)
    }
    
    private func didSelectPlaylist(_ playlist: SimplifiedPlaylist) {
        SpotifyPlayer.shared.playPlaylist(playlist.id, from: self)
    }
    
    private func didSelectAlbum(_ album: SimplifiedAlbum) {
        SpotifyPlayer.shared.playAlbum(album, from: self)
    }
    
    private func didSelectArtist(_ artist: Artist) {
        pushController(withName: "Artist Detail", context: artist)
    }
}

// MARK: - Search

extension SearchInterfaceController {
    
    private func performSearch(with keyword: String) {
        SpotifyServiceProvider.shared.search(keyword) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    strongSelf.handleSearchResponse(response)
                }
            case .failure:
                DispatchQueue.main.async {
                    strongSelf.handleSearchFailure()
                }
            }
        }
    }
    
    private func handleSearchResponse(_ response: SearchResponse) {
        loadingIndicator.stopAnimating()
        loadingIndicator.setHidden(true)
        
        var rows: [RowContent] = []
        
        if let tracks = response.tracks, !tracks.items.isEmpty {
            rows.append(.header("Songs"))
            rows.append(contentsOf: tracks.items.prefix(upTo: min(4, tracks.items.count)).map { .track($0) })
        }
        
        if let playlists = response.playlists, !playlists.items.isEmpty {
            rows.append(.header("Playlists"))
            
            let chunkedPlaylists = Array(playlists.items.prefix(upTo: min(4, playlists.items.count))).chunked(into: 2)
            rows.append(contentsOf: chunkedPlaylists.map { .playlistsTuple($0) })
        }
        
        if let albums = response.albums, !albums.items.isEmpty {
            rows.append(.header("Albums"))
            
            let chunkedAlbums = Array(albums.items.prefix(upTo: min(4, albums.items.count))).chunked(into: 2)
            rows.append(contentsOf: chunkedAlbums.map { .albumsTuple($0) })
        }
        
        if let artists = response.artists, !artists.items.isEmpty {
            rows.append(.header("Artists"))
            rows.append(contentsOf: artists.items.prefix(upTo: min(4, artists.items.count)).map { .artist($0) })
        }
        
        guard !rows.isEmpty else {
            noResultLabel.setHidden(false)
            return
        }
        
        resultTable.setRowTypes(rows.map { $0.rowType })

        for (idx, rowContent) in rows.enumerated() {
            switch rowContent {
            case .header(let text):
                let controller = resultTable.rowController(at: idx) as! HeaderRowController
                controller.label.setText(text)
                
            case .track(let track):
                let controller = resultTable.rowController(at: idx) as! SearchResultRowController
                controller.configure(with: track)
                
            case .playlistsTuple(let playlists):
                let controller = resultTable.rowController(at: idx) as! PlaylistDualItemController
                controller.configure(playlists) { [weak self] playlist in
                    self?.didSelectPlaylist(playlist)
                }
                
            case .albumsTuple(let albums):
                let controller = resultTable.rowController(at: idx) as! AlbumDualItemController
                controller.configure(albums) { [weak self] album in
                    self?.didSelectAlbum(album)
                }
                
            case .artist(let artist):
                let controller = resultTable.rowController(at: idx) as! SearchResultRowController
                controller.configure(with: artist)
            }
        }
        
        self.rows = rows
        resultTable.setHidden(false)
    }
    
    private func handleSearchFailure() {
        pop()
    }
}

// MARK: - Enum

extension SearchInterfaceController {
    
    enum RowContent {
        case header(String)
        case track(Track)
        case playlistsTuple([SimplifiedPlaylist])
        case albumsTuple([SimplifiedAlbum])
        case artist(Artist)
        
        var rowType: String {
            switch self {
            case .header:
                return "header"
            case .track:
                return "item"
            case .playlistsTuple:
                return "playlist"
            case .albumsTuple:
                return "album"
            case .artist:
                return "item"
            }
        }
    }
}
