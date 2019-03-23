//
//  Paginated.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct Paginated<T: Codable>: Codable {
    public let href: String
    public let items: [T]
    public let limit: Int
    public let offset: Int
    public let total: Int

    public let next: URL?
    public let previous: URL?
}
