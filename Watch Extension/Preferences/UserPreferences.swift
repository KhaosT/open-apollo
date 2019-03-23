//
//  UserPreferences.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

class UserPreferences {
    
    static var shuffle: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "enableShuffle")
        }
        
        get {
            return UserDefaults.standard.bool(forKey: "enableShuffle")
        }
    }
}
