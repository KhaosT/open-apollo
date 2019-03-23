//
//  SimplifiedPlaylist.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct SimplifiedPlaylist: Codable {
    public let id: String
    public let name: String
    
    public let images: [Image]
    
    public let collaborative: Bool
    public let tracks: TracksLink
}

extension SimplifiedPlaylist {
    
    public struct TracksLink: Codable {
        public let href: URL
        public let total: Int
    }
}

extension SimplifiedPlaylist: AnyPlaylist {}
