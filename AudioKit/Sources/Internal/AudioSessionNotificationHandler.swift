//
//  AudioSessionNotificationHandler.swift
//  AudioKit
//
//  Created by Khaos Tian on 9/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import AVFoundation

class AudioSessionNotificationHandler: NSObject {
    
    var interruptionBeganHandler: (() -> Void)?
    var interruptionEndedHandler: ((AVAudioSession.InterruptionOptions) -> Void)?
    var routeChangeHandler: ((AVAudioSession.RouteChangeReason, [AnyHashable : Any]) -> Void)?
    var mediaServicesResetHandler: (() -> Void)?
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruption(notification:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleMediaServicesWereReset(notification:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }
}

// MARK: - Notification Handler

extension AudioSessionNotificationHandler {
    
    @objc
    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch type {
        case .began:
            interruptionBeganHandler?()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                interruptionEndedHandler?(options)
            }
        @unknown default:
            break
        }
    }
    
    @objc
    private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        routeChangeHandler?(reason, userInfo)
    }
    
    @objc
    private func handleMediaServicesWereReset(notification: Notification) {
        mediaServicesResetHandler?()
    }
}
