//
//  PlaybackState.swift
//  Apollo
//
//  Created by Khaos Tian on 10/18/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public enum PlaybackState {
    case loading
    case buffering
    case playing
    case paused
    case stopped
    case interrupted
    
    public var isActive: Bool {
        switch self {
        case .loading,
             .buffering,
             .playing,
             .paused,
             .interrupted:
            return true
        case .stopped:
            return false
        }
    }
}
