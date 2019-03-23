//
//  DownloadTaskRowController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class DownloadTaskRowController: NSObject {
    @IBOutlet weak var titleLabel: WKInterfaceLabel?
    @IBOutlet weak var subtitleLabel: WKInterfaceLabel?
    
    func configure(with task: URLSessionDownloadTask) {
        if let rawIdentifier = task.taskDescription,
            let taskIdentifier = DownloadManager.TaskIdentifier(rawIdentifier) {
            switch taskIdentifier {
            case .artwork:
                titleLabel?.setText("🌌 Artwork")
            case .track(let itemId, _):
                if let cachedTrack = LocalStorageManager.shared.cachedTrack(trackId: itemId) {
                    titleLabel?.setText("🎵 " + cachedTrack.name)
                } else {
                    titleLabel?.setText("🎵 Audio File")
                }
            }
        } else {
            titleLabel?.setText("🎲 Download Task")
        }
        
        subtitleLabel?.setText(String(format: "%.2f%%", task.progress.fractionCompleted * 100))
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateNotification(_:)), name: .downloadManagerTaskProgressUpdate, object: task)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    private func handleUpdateNotification(_ notification: Notification) {
        guard let task = notification.object as? URLSessionDownloadTask else {
            return
        }
        
        let progressString = String(format: "%.2f%%", task.progress.fractionCompleted * 100)
        
        DispatchQueue.main.async { [weak self] in
            self?.subtitleLabel?.setText(progressString)
        }
    }
}
