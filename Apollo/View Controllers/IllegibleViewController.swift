//
//  IllegibleViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 10/29/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class IllegibleViewController: StepViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        heroImageView.image = UIImage(named: "Oops")
        titleLabel.text = "Oops…"
        descriptionLabel.text = "Unfortunately, Apollo only works with Spotify Premium account."
        
        setupActionButton()
    }
    
    private func setupActionButton() {
        let button = ActionButton(type: .system)
        button.backgroundColor = Color.green
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Sign Out", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(didTapSignOut), for: .touchUpInside)
        
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ]
        )
    }
    
    @objc
    private func didTapSignOut() {
        ConfigurationServices.shared.currentConfiguration = nil
        WatchCommunicationManager.shared.syncIfPossible()
        
        let viewController = WelcomeViewController()
        navigationController?.setViewControllers([viewController], animated: true)
    }
}
