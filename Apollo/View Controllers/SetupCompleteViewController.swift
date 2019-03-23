//
//  SetupCompleteViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 10/29/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit

class SetupCompleteViewController: StepViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        heroImageView.image = UIImage(named: "Watch-Done")
        titleLabel.text = "Done!"
        
        let descriptionAttributedString = NSMutableAttributedString(
            string: "Enjoy the music on your Apple Watch.\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white
            ]
        )
        
        descriptionAttributedString.append(
            NSAttributedString(
                string: "If your Apple Watch does not have cellular connectivity, you can download playlists for offline playback from the Watch app.",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                    .foregroundColor: UIColor.lightGray
                ]
            )
        )
        
        descriptionLabel.attributedText = descriptionAttributedString
        
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
        let alert = UIAlertController(title: "Sign Out?", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(
            UIAlertAction(
                title: "Yes",
                style: .destructive,
                handler: { _ in
                    ConfigurationServices.shared.currentConfiguration = nil
                    WatchCommunicationManager.shared.syncIfPossible()
                    
                    let viewController = WelcomeViewController()
                    self.navigationController?.setViewControllers([viewController], animated: true)
                }
            )
        )
        
        present(alert, animated: true, completion: nil)
    }
}
