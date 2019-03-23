//
//  AudioTrackMetadata.swift
//  AudioKit
//
//  Created by Khaos Tian on 9/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import MediaPlayer

public struct AudioTrackMetadata {
    
    public var title: String?
    public var artist: String?
    public var composer: String?
    
    public var genre: String?
    
    public var albumTitle: String?
    public var albumArtist: String?
    
    public var duration: TimeInterval?
    public var artwork: MPMediaItemArtwork?
    
    public init() {}
}

extension AudioTrackMetadata {
    
    var nowPlayingInfo: [String: Any] {
        var nowPlayingInfo: [String : Any] = [:]
        
        if let title = title {
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
        }
        
        if let artist = artist {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        if let genre = genre {
            nowPlayingInfo[MPMediaItemPropertyGenre] = genre
        }
        
        if let albumTitle = albumTitle {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle
        }
        
        if let albumArtist = albumArtist {
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = albumArtist
        }
        
        if let duration = duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        if let artwork = artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        return nowPlayingInfo
    }
}
