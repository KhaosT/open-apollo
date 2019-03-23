//
//  SimplifiedTrack.swift
//  Apollo
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct SimplifiedTrack: Codable {
    public let id: String
    public let name: String
    
    public let isLocal: Bool
    
    public let discNumber: Int
    public let trackNumber: Int
    
    public let artists: [SimplifiedArtist]
    
    public let durationMs: Int
    public let explicit: Bool
}
