//
//  SpotifyAuthorizationContext.swift
//  Apollo
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

class SpotifyAuthorizationContext {
    
    static let clientId: String = <#YOUR_CLIENT_ID#>
    static let callbackURLScheme: String = <#YOUR_CALLBACK_URL_SCHEME#>
    
    static func authorizationRequestURL() -> URL {
        var urlComponents = URLComponents(string: "https://accounts.spotify.com/authorize")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: <#CALLBACK_URL#>),
            URLQueryItem(name: "scope", value: "playlist-read-collaborative playlist-modify-public playlist-read-private playlist-modify-private user-read-currently-playing user-modify-playback-state user-read-playback-state user-follow-read user-follow-modify user-read-private user-read-email user-library-read user-library-modify app-remote-control streaming user-top-read user-read-recently-played")
        ]
        
        return urlComponents.url!
    }
}
