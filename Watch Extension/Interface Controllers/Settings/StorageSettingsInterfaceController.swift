//
//  StorageSettingsInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class StorageSettingsInterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    @IBAction func didTapDeleteCache() {
        LocalStorageManager.shared.evictTemporaryStorage()
    }
    
    @IBAction func didTapDeleteDownload() {
        LocalStorageManager.shared.evictDownloadStorage()
    }
}
