//
//  Track.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct Track: Codable {
    public let id: String
    public let name: String
    
    public let isLocal: Bool
    
    public let discNumber: Int
    public let trackNumber: Int
    
    public let popularity: Int?
    
    public let album: SimplifiedAlbum
    public let artists: [SimplifiedArtist]
    
    public let durationMs: Int
    public let explicit: Bool
}

extension Track {
    
    public init(simplifiedTrack: SimplifiedTrack, album: Album) {
        self.id = simplifiedTrack.id
        self.name = simplifiedTrack.name
        self.isLocal = simplifiedTrack.isLocal
        self.discNumber = simplifiedTrack.discNumber
        self.trackNumber = simplifiedTrack.trackNumber
        self.popularity = nil
        self.album = SimplifiedAlbum(album: album)
        self.artists = simplifiedTrack.artists
        self.durationMs = simplifiedTrack.durationMs
        self.explicit = simplifiedTrack.explicit
    }
}
