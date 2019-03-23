//
//  DebugServices.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/18/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit

class DebugServices {
    
    static func presentMessage(_ message: String) {
        DispatchQueue.main.async {
            WKExtension.shared().visibleInterfaceController?.presentAlert(
                withTitle: "Oops",
                message: message,
                preferredStyle: .alert,
                actions: [
                    WKAlertAction(
                        title: "OK",
                        style: .cancel,
                        handler: {}
                    )
                ]
            )
        }
    }
}
