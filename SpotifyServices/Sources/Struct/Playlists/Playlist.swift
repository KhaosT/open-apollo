//
//  Playlist.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct Playlist: Codable {
    public let id: String
    public let name: String
    public let owner: PublicUser
    
    public let description: String?
    public let images: [Image]
    
    public let followers: Followers
    
    public let collaborative: Bool
    public let tracks: Paginated<PlaylistTrack>
}

extension Playlist: AnyPlaylist {}
