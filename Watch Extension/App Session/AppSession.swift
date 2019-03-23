//
//  AppSession.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class AppSession {
    
    static let shared = AppSession()
    
    private let communicator = CompanionCommunicator()
    
    var didTransitionToHome = false
    var isUpdating = false
    var offline = false
    
    func start() {
        configureLogging()

        if let configuration = ConfigurationServices.shared.currentConfiguration {
            SpotifyServiceProvider.shared.configure(with: configuration)
            initializeSpotifyService()
        } else {
            transitionToSyncScreen()
        }
        
        communicator.start()
        
        DispatchQueue.global().async {
            DownloadManager.shared.handleSessionUpdate(nil)
        }
    }
    
    func handleApplicationDidBecomeActive() {
        guard !didTransitionToHome, !isUpdating, SpotifyServiceProvider.shared.currentConfiguration != nil else {
            return
        }
        
        initializeSpotifyService()
    }
}

// MARK: - Transition

extension AppSession {
    
    func reloadWithOfflineMode() {
        offline = true
        transitionToHomeScreen()
    }
    
    private func transitionToSyncScreen() {
        didTransitionToHome = false
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["Message"],
            contexts: [
                DisplayMessage(
                    imageName: "Sync",
                    title: "Setup",
                    message: "Please open Apollo on your iPhone and finish setup there."
                )
            ],
            orientation: .horizontal,
            pageIndex: 0
        )
    }
    
    private func transitionToInitializationScreen() {
        didTransitionToHome = false
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["Initialization"],
            contexts: nil,
            orientation: .horizontal,
            pageIndex: 0
        )
    }
    
    private func transitionToIllegibleScreen() {
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["Message"],
            contexts: [
                DisplayMessage(
                    imageName: "Oops",
                    title: "Oops…",
                    message: "Unfortunately, Apollo only works with Spotify Premium account."
                )
            ],
            orientation: .horizontal,
            pageIndex: 0
        )
    }
    
    private func transitionToHomeScreen() {
        guard !didTransitionToHome else {
            return
        }
        
        didTransitionToHome = true
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["Home"],
            contexts: nil,
            orientation: .horizontal,
            pageIndex: 0
        )
    }
    
    private func presentErrorAlert(_ error: Error) {
        guard WKExtension.shared().applicationState == .active else {
            return
        }
        
        WKExtension.shared().visibleInterfaceController?.presentAlert(
            withTitle: "Oops",
            message: error.localizedDescription,
            preferredStyle: .alert,
            actions: [
                WKAlertAction(
                    title: "Try Again",
                    style: .default,
                    handler: { [weak self] in
                        self?.initializeSpotifyService()
                    }
                ),
                WKAlertAction(
                    title: "OK",
                    style: .cancel,
                    handler: {}
                )
            ]
        )
    }
}

// MARK: - Spotify Service

extension AppSession {
    
    private func initializeSpotifyService() {
        guard !isUpdating else {
            return
        }
        
        isUpdating = true
        SpotifyServiceProvider.shared.start { result in
            DispatchQueue.main.async {
                self.isUpdating = false
            }
            
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    if user.hasPremiumSubscription {
                        self.transitionToHomeScreen()
                    } else {
                        self.transitionToIllegibleScreen()
                    }
                }
            case .failure(let error):
                guard !self.offline else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.presentErrorAlert(error)
                }
            }
        }
    }
}

// MARK: - Download

extension AppSession {
    
    func handleURLSessionUpdate(_ task: WKURLSessionRefreshBackgroundTask) {
        DownloadManager.shared.handleSessionUpdate {
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}

// MARK: - Configuration Sync

extension AppSession {
    
    func handleCompanionMessage(_ message: [String: Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let rawMessageType = message[WatchMessage.MessageKey.type] as? String,
            let messageType = WatchMessage.MessageType(rawValue: rawMessageType) else {
                replyHandler(
                    [
                        WatchMessage.MessageKey.error: WatchMessage.MessageError.unknown.rawValue
                    ]
                )
                return
        }
        
        switch messageType {
        case .configurationSync:
            if let configurationData = message["configuration"] as? Data {
                do {
                    let configuration = try JSONDecoder().decode(ServiceConfiguration.self, from: configurationData)
                    
                    if configuration.configurationIdentifier != ConfigurationServices.shared.currentConfiguration?.configurationIdentifier {
                        ConfigurationServices.shared.currentConfiguration = configuration
                        SpotifyServiceProvider.shared.configure(with: configuration)
                        DispatchQueue.main.async {
                            self.transitionToInitializationScreen()
                            self.initializeSpotifyService()
                        }
                    }
                    
                    replyHandler(
                        [
                            WatchMessage.MessageKey.ack: true
                        ]
                    )
                } catch {
                    NSLog("Error: \(error)")
                    replyHandler(
                        [
                            WatchMessage.MessageKey.ack: false
                        ]
                    )
                }
            } else {
                ConfigurationServices.shared.currentConfiguration = nil
                
                DispatchQueue.main.async {
                    SpotifyPlayer.shared.player.stop()
                    self.transitionToSyncScreen()
                }
                
                replyHandler(
                    [
                        WatchMessage.MessageKey.ack: true
                    ]
                )
            }
        }
    }
}

// MARK: - Logging

extension AppSession {
    
    private func configureLogging() {
        LogConfiguration.configure { message in
            DebugServices.presentMessage(message)
        }
    }
}
