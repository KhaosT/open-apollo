//
//  HelloViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import SpotifyServices

class HelloViewController: StepViewController {

    private let currentUser: User
    
    required init(_ user: User) {
        self.currentUser = user
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        heroImageView.image = UIImage(named: "Music")
        
        let titleAttributedString = NSMutableAttributedString(
            string: "Hello,\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        
        titleAttributedString.append(
            NSAttributedString(
                string: "\(currentUser.firstName).",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                    .foregroundColor: Color.green
                ]
            )
        )
        
        titleLabel.attributedText = titleAttributedString
        titleLabel.numberOfLines = 0
        descriptionLabel.text = "Enjoy the music on your Apple Watch."
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "InformationItem"), style: .plain, target: self, action: #selector(presentAboutScreen))
        
        setupActionButton()
    }
    
    @objc
    private func presentAboutScreen() {
        let viewController = AboutViewController()
        let navigationController = BaseNavigationViewController()
        navigationController.prefersTransparentNavigationBar = false
        navigationController.viewControllers = [viewController]
        present(navigationController, animated: true, completion: nil)
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
