//
//  User.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct User: Codable {
    public let id: String
    public let country: String
    public let displayName: String?
    public let images: [Image]
    public let followers: Followers
    public let product: String
}

extension User {
    
    public var firstName: String {
        guard let displayName = displayName else {
            return id
        }
        return displayName.components(separatedBy: " ").first!
    }
    
    public var hasPremiumSubscription: Bool {
        return product == "premium"
    }
}
