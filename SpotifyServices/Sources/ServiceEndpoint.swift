//
//  ServiceEndpoint.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

enum ServiceEndpoint {
    case userProfile
    case recentlyPlayed
    case myPlaylists
    case playlist(String)
    case album(String)
    case artistAlbums(String)
    case categories
    case categoryPlaylists(String)
    case featuredPlaylists
    case newReleases
    case search
    case track(String)
}

extension ServiceEndpoint {
    
    var url: URL {
        switch self {
        case .userProfile:
            return URL(string: "https://api.spotify.com/v1/me")!
        case .recentlyPlayed:
            return URL(string: "https://api.spotify.com/v1/me/player/recently-played")!
        case .myPlaylists:
            return URL(string: "https://api.spotify.com/v1/me/playlists")!
        case .playlist(let id):
            return URL(string: "https://api.spotify.com/v1/playlists/\(id)")!
        case .album(let id):
            return URL(string: "https://api.spotify.com/v1/albums/\(id)")!
        case .artistAlbums(let id):
            return URL(string: "https://api.spotify.com/v1/artists/\(id)/albums")!
        case .categories:
            return URL(string: "https://api.spotify.com/v1/browse/categories")!
        case .categoryPlaylists(let id):
            return URL(string: "https://api.spotify.com/v1/browse/categories/\(id)/playlists")!
        case .featuredPlaylists:
            return URL(string: "https://api.spotify.com/v1/browse/featured-playlists")!
        case .newReleases:
            return URL(string: "https://api.spotify.com/v1/browse/new-releases")!
        case .search:
            return URL(string: "https://api.spotify.com/v1/search")!
        case .track(let id):
            return URL(string: "https://api.spotify.com/v1/tracks/\(id)")!
        }
    }
}
