//
//  TokenSyncViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class TokenSyncViewController: StepViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        heroImageView.image = UIImage(named: "Watch-Setup")
        titleLabel.text = "Almost there"
        descriptionLabel.text = "Please open Apollo on your Apple Watch to complete the setup."
        
        setupNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WatchCommunicationManager.shared.start()
    }
}

// MARK: - Notification

extension TokenSyncViewController {
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSyncCompleteNotification(_:)), name: .configurationSyncComplete, object: nil)
    }
    
    @objc
    private func handleSyncCompleteNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            let viewController = SetupCompleteViewController()
            self.navigationController?.setViewControllers([viewController], animated: true)
        }
    }
}
