//
//  DetailTableViewCell.swift
//  Apollo
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class DetailTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor(hue: 0.6111, saturation: 0.1, brightness: 0.12, alpha: 1.0)
        self.textLabel?.textColor = UIColor.white
        self.detailTextLabel?.textColor = UIColor.lightGray
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(hue: 0.58333, saturation: 0.04, brightness: 0.21, alpha: 1.0)
        self.selectedBackgroundView = backgroundView
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
