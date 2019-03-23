//
//  ExploreInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import WatchKit
import SpotifyServices

class ExploreInterfaceController: WKInterfaceController {

    @IBOutlet weak var loadingIndicator: WKInterfaceImage!
    
    @IBOutlet weak var featuredPlaylistsGroup: WKInterfaceGroup!
    @IBOutlet weak var featuredPlaylistsLabel: WKInterfaceLabel!
    @IBOutlet weak var featuredPlaylistsTable: WKInterfaceTable!
    
    @IBOutlet weak var categoriesGroup: WKInterfaceGroup!
    @IBOutlet weak var categoriesTable: WKInterfaceTable!
    
    private var featuredPlaylists: FeaturedPlaylistsResponse?
    private var categories: CategoriesResponse?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        loadContent()
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if table == categoriesTable, let category = categories?.categories.items[rowIndex] {
            didSelectCategory(category)
        }
    }
}

// MARK: - Action

extension ExploreInterfaceController {
    
    private func didSelectPlaylist(_ playlist: SimplifiedPlaylist) {
        SpotifyPlayer.shared.playPlaylist(playlist.id, from: self)
    }
    
    private func didSelectCategory(_ category: SpotifyServices.Category) {
        pushController(withName: "Category Detail", context: category)
    }
}

// MARK: - Content

extension ExploreInterfaceController {
    
    private func loadContent() {
        let group = DispatchGroup()
        
        group.enter()
        SpotifyServiceProvider.shared.getFeaturedPlaylists { [weak self] result in
            self?.featuredPlaylists = result.value
            group.leave()
        }
        
        group.enter()
        SpotifyServiceProvider.shared.getCategories { [weak self] result in
            self?.categories = result.value
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.loadingIndicator.setHidden(true)
            self?.updateContent()
        }
    }
    
    private func updateContent() {
        if let featuredPlaylists = featuredPlaylists {
            featuredPlaylistsGroup.setHidden(false)
            featuredPlaylistsLabel.setText(featuredPlaylists.message ?? "Featured Playlists")
            
            let playlists = featuredPlaylists.playlists.items.chunked(into: 2)
            featuredPlaylistsTable.setNumberOfRows(playlists.count, withRowType: "playlists")
            
            for (idx, playlistTuple) in playlists.enumerated() {
                let rowController = featuredPlaylistsTable.rowController(at: idx) as! PlaylistDualItemController
                rowController.configure(
                    playlistTuple,
                    selectionHandler: { [weak self] playlist in
                        self?.didSelectPlaylist(playlist)
                    }
                )
            }
        }
        
        if let categories = categories {
            categoriesGroup.setHidden(false)
            categoriesTable.setNumberOfRows(categories.categories.items.count, withRowType: "category")
            
            for (idx, category) in categories.categories.items.enumerated() {
                let rowController = categoriesTable.rowController(at: idx) as! CategoryRowController
                rowController.label.setText(category.name)
            }
        }
    }
}
