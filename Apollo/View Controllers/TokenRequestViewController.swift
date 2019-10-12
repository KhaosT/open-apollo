//
//  TokenRequestViewController.swift
//  Apollo
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import SpotifyServices

class TokenRequestViewController: BaseViewController {

    private let code: String
    
    private lazy var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    required init(_ code: String) {
        self.code = code
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
        requestToken()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        activityIndicator.stopAnimating()
    }
}

// MARK: - Request Token

extension TokenRequestViewController {
    
    private func requestToken() {
        let url = DefaultServiceConfiguration.serviceURL.appendingPathComponent("/token")
        var request = URLRequest(url: url)
        
        let requestBody = [
            "code": code
        ]
        
        guard let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            showErrorAlert(message: "[Token] An error has occurred. Please try again later. (JSON_ENCODING_FAILURE)")
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: "[Token] An error has occurred. Please try again later. Response: \(String(describing: response)). Error: \(String(describing: error))")
                }
                return
            }
            
            if let responseObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let refreshToken = responseObject["refresh_token"] as? String {
                    DispatchQueue.main.async {
                        self?.processRefreshToken(refreshToken)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showErrorAlert(message: "[Token] Unexpected response received. Please try again later. Response: \(String(describing: responseObject))")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: "[Token] Unexpected response received. Please try again later. \(data)")
                }
            }
        }
        
        task.resume()
    }
    
    private func processRefreshToken(_ token: String) {
        let configuration = ServiceConfiguration(
            serviceURL: DefaultServiceConfiguration.serviceURL,
            trackServiceURL: DefaultServiceConfiguration.trackServiceURL,
            refreshToken: token
        )
        
        ConfigurationServices.shared.currentConfiguration = configuration
        SpotifyServiceProvider.shared.configure(with: configuration)
        SpotifyServiceProvider.shared.start { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if user.hasPremiumSubscription {
                        self?.transitionToSync()
                    } else {
                        self?.transitionToIllegible()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    ConfigurationServices.shared.currentConfiguration = nil
                    self?.showErrorAlert(message: "[Token] An error has occurred. Please try again later. (START_ERROR) Error: \(error)")
                }
            }
        }
    }
    
    private func transitionToSync() {
        let viewController = TokenSyncViewController()
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
                    self?.navigationController?.popViewController(animated: true)
                }
            )
        )
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Setup

extension TokenRequestViewController {
    
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
