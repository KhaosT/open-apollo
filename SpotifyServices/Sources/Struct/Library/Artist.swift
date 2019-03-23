//
//  Artist.swift
//  Apollo
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct Artist: Codable {
    public let id: String
    public let name: String
    public let followers: Followers
    public let images: [Image]
    public let popularity: Int
}
