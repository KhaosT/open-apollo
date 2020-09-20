//
//  DownloadPlaylistInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class DownloadPlaylistInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var loadingIndicator: WKInterfaceImage!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var messageLabel: WKInterfaceLabel!
    
    private var isDownloading = false
    private var playlist: SimplifiedPlaylist!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let context = context as? SimplifiedPlaylist else {
            fatalError()
        }
        
        playlist = context
        startDownload()
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}

// MARK: - Download

extension DownloadPlaylistInterfaceController {
    
    private func startDownload() {
        guard !isDownloading else {
            return
        }
        
        isDownloading = true
        
        DownloadManager.shared.download(with: .shared, playlist: playlist) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    strongSelf.loadingIndicator.stopAnimating()
                    strongSelf.loadingIndicator.setHidden(true)
                    strongSelf.titleLabel.setText("Download Started")
                    strongSelf.messageLabel.setText("Downloading \"\(strongSelf.playlist.name)\" now.\n\nPlease make sure the app remains open until the download complete. You can check the progress under Downloads section.")
                }
            case .failure(let error):
                DebugServices.presentMessage(String(describing: error))
            }
        }
    }
}
