//
//  FeaturedPlaylistsResponse.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct FeaturedPlaylistsResponse: Codable {
    public let message: String?
    public let playlists: Paginated<SimplifiedPlaylist>
}
