//
//  WatchCommunicationManager.swift
//  Apollo
//
//  Created by Khaos Tian on 10/29/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchCommunicationManager: NSObject {
    
    static let shared = WatchCommunicationManager()
    
    func start() {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.default
        
        session.delegate = self
        session.activate()
    }
    
    func syncIfPossible() {
        guard WCSession.default.activationState == .activated else {
            return
        }
        
        syncCurrentConfiguration()
    }
}

// MARK: - Sync Current Configuration

extension WatchCommunicationManager {
    
    private func syncCurrentConfiguration() {
        let session = WCSession.default
        
        guard session.isReachable else {
            return
        }
        
        NSLog("Reachable - Attempt To Sync")
        
        if let currentConfiguration = ConfigurationServices.shared.currentConfiguration {
            do {
                let data = try JSONEncoder().encode(currentConfiguration)
                session.sendMessage(
                    [
                        WatchMessage.MessageKey.type: WatchMessage.MessageType.configurationSync.rawValue,
                        "configuration": data
                    ],
                    replyHandler: { response in
                        NSLog("Response: \(response)")
                        NotificationCenter.default.post(name: .configurationSyncComplete, object: nil)
                    },
                    errorHandler: { error in
                        NSLog("Error: \(error)")
                    }
                )
            } catch {
                NSLog("Encode Error: \(error)")
            }
        } else {
            session.sendMessage(
                [
                    WatchMessage.MessageKey.type: WatchMessage.MessageType.configurationSync.rawValue
                ],
                replyHandler: { response in
                    NSLog("Response: \(response)")
                    NotificationCenter.default.post(name: .configurationSyncComplete, object: nil)
                },
                errorHandler: { error in
                    NSLog("Error: \(error)")
                }
            )
        }       
    }
}

// MARK: - Notification

extension Notification.Name {
    
    static let configurationSyncComplete = Notification.Name("WatchCommunicationManager.configurationSyncComplete")
}

// MARK: - WCSessionDelegate

extension WatchCommunicationManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("ActivationDidCompleteWithState: \(activationState.rawValue), error: \(String(describing: error))")
        switch activationState {
        case .activated:
            syncCurrentConfiguration()
        case .inactive:
            break
        case .notActivated:
            break
        @unknown default:
            break
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        NSLog("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        NSLog("sessionDidDeactivate")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        NSLog("sessionWatchStateDidChange:\n\t-isPaired: \(session.isPaired)\n\t-isWatchAppInstalled: \(session.isWatchAppInstalled)\n\t-isComplicationEnabled: \(session.isComplicationEnabled)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        NSLog("sessionReachabilityDidChange: \(session.isReachable)")
        if session.isReachable {
            syncCurrentConfiguration()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        NSLog("Message: \(message)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        NSLog("Message: \(message); with replyHandler")
    }
}
