//
//  CompanionCommunicator.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import WatchConnectivity

class CompanionCommunicator: NSObject {
    
    func start() {
        guard WCSession.isSupported() else {
            return
        }
        
        let session = WCSession.default
        
        session.delegate = self
        session.activate()
    }
}

extension CompanionCommunicator: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("ActivationDidCompleteWithState: \(activationState.rawValue), error: \(String(describing: error))")

        switch activationState {
        case .activated:
            break
        case .inactive:
            break
        case .notActivated:
            break
        @unknown default:
            break
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        NSLog("sessionReachabilityDidChange: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        NSLog("Message: \(message)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        AppSession.shared.handleCompanionMessage(message, replyHandler: replyHandler)
    }
}
