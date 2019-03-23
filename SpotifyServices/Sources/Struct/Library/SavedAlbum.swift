//
//  SavedAlbum.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct SavedAlbum: Codable {
    public let addedAt: Date?
    public let album: Album
}
