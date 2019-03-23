//
//  Album+Enums.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public enum AlbumGroup: String, Codable {
    case album
    case single
    case compilation
    case appearsOn = "appears_on"
}

public enum AlbumType: String, Codable {
    case album
    case single
    case compilation
}

public enum AlbumReleaseDatePrecision: String, Codable {
    case year
    case month
    case day
}
