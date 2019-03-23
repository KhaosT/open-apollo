//
//  TrackFileInfo.swift
//  Apollo
//
//  Created by Khaos Tian on 10/13/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

struct TrackFileInfo: Codable {
    let trackId: String
    let fileId: String
    let trackKey: String
}

extension TrackFileInfo {
    
    var trackKeyData: Data {
        return Data(base64Encoded: trackKey)!
    }
}

struct TracksInfo: Codable {
    
    let tracks: [TrackFileInfo]
}
