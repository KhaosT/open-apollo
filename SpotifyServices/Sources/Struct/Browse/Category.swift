//
//  Category.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct Category: Codable {
    public let id: String
    public let name: String
    public let icons: [Image]
}
