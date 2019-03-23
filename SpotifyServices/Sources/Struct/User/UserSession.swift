//
//  UserSession.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct UserSession {
    public let accessToken: String
    public let expireAt: Date
}

extension UserSession {
    
    var authorizationValue: String {
        return "Bearer \(accessToken)"
    }
    
    var isExpired: Bool {
        return Date() > expireAt
    }
}
