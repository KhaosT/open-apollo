//
//  WatchMessage.swift
//  Apollo
//
//  Created by Khaos Tian on 10/29/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

struct WatchMessage {
    
    struct MessageKey {
        static let type = "t"
        static let error = "e"
        static let ack = "a"
    }
    
    enum MessageType: String {
        case configurationSync = "c"
    }
    
    enum MessageError: Int {
        case unknown
    }
}
