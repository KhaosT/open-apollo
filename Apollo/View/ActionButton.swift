//
//  ActionButton.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class ActionButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height * 0.5
    }
}
