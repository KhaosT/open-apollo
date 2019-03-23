//
//  MessageInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import Foundation

class MessageInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var imageView: WKInterfaceImage!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var messageLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let message = context as? DisplayMessage else {
            fatalError()
        }
        
        imageView.setImageNamed(message.imageName)
        titleLabel.setText(message.title)
        messageLabel.setText(message.message)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}

struct DisplayMessage {
    let imageName: String
    let title: String
    let message: String
}
