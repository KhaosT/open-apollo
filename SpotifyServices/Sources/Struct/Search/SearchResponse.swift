//
//  SearchResponse.swift
//  Apollo
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct SearchResponse: Codable {
    public let albums: Paginated<SimplifiedAlbum>?
    public let artists: Paginated<Artist>?
    public let tracks: Paginated<Track>?
    public let playlists: Paginated<SimplifiedPlaylist>?
}
