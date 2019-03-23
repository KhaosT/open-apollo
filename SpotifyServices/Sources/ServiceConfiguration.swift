//
//  ServiceConfiguration.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public struct ServiceConfiguration: Codable {
    
    public let configurationIdentifier: UUID
    public let serviceURL: URL
    public let trackServiceURL: URL
    public let refreshToken: String

    public init(serviceURL: URL, trackServiceURL: URL, refreshToken: String) {
        self.configurationIdentifier = UUID()
        self.serviceURL = serviceURL
        self.trackServiceURL = trackServiceURL
        self.refreshToken = refreshToken
    }
}
