//
//  BaseNavigationViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class BaseNavigationViewController: UINavigationController {

    var prefersTransparentNavigationBar = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if prefersTransparentNavigationBar {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
        }
        
        navigationBar.barStyle = .black
    }
}
