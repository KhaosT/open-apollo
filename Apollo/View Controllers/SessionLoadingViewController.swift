//
//  SessionLoadingViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import SpotifyServices

class SessionLoadingViewController: BaseViewController {
    
    private lazy var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
        loadUserInfo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        activityIndicator.stopAnimating()
    }
}

// MARK: - Request Token

extension SessionLoadingViewController {
    
    private func loadUserInfo() {
        SpotifyServiceProvider.shared.start { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if user.hasPremiumSubscription {
                        self?.transitionToHello(user)
                    } else {
                        self?.transitionToIllegible()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: "[Session] An error has occurred. Please try again later. \(error)")
                }
            }
        }
    }
    
    private func transitionToHello(_ user: User) {
        let viewController = HelloViewController(user)
        navigationController?.setViewControllers([viewController], animated: true)
    }
    
    private func transitionToIllegible() {
        let viewController = IllegibleViewController()
        navigationController?.setViewControllers([viewController], animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Oops",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .cancel,
                handler: { [weak self] _ in
                    ConfigurationServices.shared.currentConfiguration = nil
                    WatchCommunicationManager.shared.syncIfPossible()
                    
                    let viewController = WelcomeViewController()
                    self?.navigationController?.setViewControllers([viewController], animated: true)
                }
            )
        )
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Setup

extension SessionLoadingViewController {
    
    private func setupView() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
            [
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )
    }
}
