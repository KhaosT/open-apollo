//
//  WelcomeViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import AuthenticationServices
import SafariServices

class WelcomeViewController: StepViewController {
    
    private var authenticationSession: ASWebAuthenticationSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        heroImageView.image = UIImage(named: "Welcome-Hero")
        titleLabel.text = "Welcome!"
        descriptionLabel.text = "Apollo is a standalone Spotify music player for Apple Watch."
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "InformationItem"), style: .plain, target: self, action: #selector(presentAboutScreen))
        
        setupView()
    }
}

// MARK: - Action

extension WelcomeViewController {
    
    @objc
    private func presentAboutScreen() {
        let viewController = AboutViewController()
        let navigationController = BaseNavigationViewController()
        navigationController.prefersTransparentNavigationBar = false
        navigationController.viewControllers = [viewController]
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - Setup

extension WelcomeViewController {
    
    private func setupView() {
        setupActionButton()
    }
    
    private func setupActionButton() {
        let infoLabel = UILabel()
        infoLabel.text = "Apollo only works with Spotify Premium account."
        infoLabel.textColor = .lightGray
        infoLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        
        let button = ActionButton(type: .system)
        button.backgroundColor = Color.green
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Get Started", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(didTapGetStartedButton), for: .touchUpInside)
        
        view.addSubview(infoLabel)
        view.addSubview(button)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                infoLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
                infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                infoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.bottomAnchor.constraint(equalTo: infoLabel.topAnchor, constant: -16)
            ]
        )
    }
}

// MARK: - Auth

extension WelcomeViewController {
    
    @objc
    private func didTapGetStartedButton() {
        authenticationSession?.cancel()
        
        let session = ASWebAuthenticationSession(
            url: SpotifyAuthorizationContext.authorizationRequestURL(),
            callbackURLScheme: SpotifyAuthorizationContext.callbackURLScheme,
            completionHandler: { [weak self] callbackURL, error in
                self?.authenticationSession = nil
                if let callbackURL = callbackURL {
                    self?.handleAuthorizeCallback(callbackURL)
                } else {
                    if let error = error as? ASWebAuthenticationSessionError {
                        switch error.code {
                        case .canceledLogin:
                            return
                        }
                    } else {
                        self?.handleAuthorizeFailure(error)
                    }
                }
            }
        )
        authenticationSession = session
        
        session.start()
    }
    
    private func handleAuthorizeCallback(_ url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            handleAuthorizeFailure(nil)
            return
        }
        
        let viewController = TokenRequestViewController(code)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func handleAuthorizeFailure(_ error: Error?) {
        let alert = UIAlertController(
            title: "Oops",
            message: "[Welcome] An error has occurred. Please try again later. (AUTH FAILURE)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
