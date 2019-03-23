//
//  Int+ShortText.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/8/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

extension Int {
    
    var shortText: String {
        if self >= 1_000_000_000 {
            return "\(self/1_000_000_000)B"
        } else if self >= 1_000_000 {
            return "\(self/1_000_000)M"
        } else if self >= 1_000 {
            return "\(self/1_000)K"
        } else {
            return "\(self)"
        }
    }
}
