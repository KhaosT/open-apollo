//
//  CategoryInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import WatchKit
import SpotifyServices

class CategoryInterfaceController: WKInterfaceController {

    @IBOutlet weak var loadingIndicator: WKInterfaceImage!
    @IBOutlet weak var playlistsTable: WKInterfaceTable!
    
    private var category: SpotifyServices.Category?
    private var playlists: [SimplifiedPlaylist] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let context = context as? SpotifyServices.Category else {
            return
        }
        
        setTitle(context.name)
        category = context
        loadContent()
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}

// MARK: - Action

extension CategoryInterfaceController {
    
    private func didSelectPlaylist(_ playlist: SimplifiedPlaylist) {
        SpotifyPlayer.shared.playPlaylist(playlist.id, from: self)
    }
}

// MARK: - Content

extension CategoryInterfaceController {
    
    private func loadContent() {
        SpotifyServiceProvider.shared.getCategoryPlaylists(for: category!.id) { [weak self] result in
            switch result {
            case .success(let response):
                self?.playlists = response.playlists.items
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.loadingIndicator.setHidden(true)
                    self?.updateContent()
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.pop()
                }
            }
        }
    }
    
    private func updateContent() {
        playlistsTable.setHidden(false)
        let playlists = self.playlists.chunked(into: 2)
        playlistsTable.setNumberOfRows(playlists.count, withRowType: "playlists")
        
        for (idx, playlistTuple) in playlists.enumerated() {
            let rowController = playlistsTable.rowController(at: idx) as! PlaylistDualItemController
            rowController.configure(
                playlistTuple,
                selectionHandler: { [weak self] playlist in
                    self?.didSelectPlaylist(playlist)
                }
            )
        }
    }
}
