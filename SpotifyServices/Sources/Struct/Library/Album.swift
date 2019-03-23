//
//  Album.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct Album: Codable {
    public let id: String
    public let name: String
    
    public let genres: [String]
    public let label: String
    
    public let images: [Image]
    
    public let popularity: Int
    
    public let releaseDate: String
    public let releaseDatePrecision: AlbumReleaseDatePrecision
    
    public let albumType: AlbumType
    public let albumGroup: AlbumGroup?
    
    public let artists: [SimplifiedArtist]
    public let tracks: Paginated<SimplifiedTrack>
}
