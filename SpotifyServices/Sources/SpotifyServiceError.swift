//
//  SpotifyServiceError.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public enum SpotifyServiceError: Error {
    case missingUserSession
    case accessTokenExpired
    case internalError
    case unknownError
    case unexpectedResponse(Any?, Error?)
    
    public var localizedDescription: String {
        switch self {
        case .missingUserSession:
            return "Unable to locate user session."
        case .accessTokenExpired:
            return "Access Token has expired."
        case .internalError:
            return "Internal Error."
        case .unknownError:
            return "Unknown Error."
        case .unexpectedResponse(let response, let error):
            return "Unexpected Response: \(String(describing: response)), Error: \(String(describing: error))"
        }
    }
}

typealias E = SpotifyServiceError
