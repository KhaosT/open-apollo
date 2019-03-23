//
//  SimplifiedAlbum.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct SimplifiedAlbum: Codable {
    public let id: String
    public let name: String
    
    public let images: [Image]
    
    public let releaseDate: String
    public let releaseDatePrecision: AlbumReleaseDatePrecision
    
    public let albumType: AlbumType
    public let albumGroup: AlbumGroup?
    
    public let artists: [SimplifiedArtist]
}

extension SimplifiedAlbum {
    
    public init(album: Album) {
        self.id = album.id
        self.name = album.name
        self.images = album.images
        self.releaseDate = album.releaseDate
        self.releaseDatePrecision = album.releaseDatePrecision
        self.albumType = album.albumType
        self.albumGroup = album.albumGroup
        self.artists = album.artists
    }
}

extension SimplifiedAlbum {
    
    public var releaseYear: Int? {
        guard let releaseYear = releaseDate.components(separatedBy: "-").first else {
            return nil
        }
        return Int(releaseYear)
    }
}
