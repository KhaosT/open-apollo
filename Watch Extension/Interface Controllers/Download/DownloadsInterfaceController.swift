//
//  DownloadsInterfaceController.swift
//  Watch Extension
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit
import SpotifyServices

class DownloadsInterfaceController: WKInterfaceController {

    @IBOutlet weak var tasksTable: WKInterfaceTable!
    
    private var tasks: [URLSessionDownloadTask] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskUpdates),
            name: .downloadManagerTaskChanges,
            object: DownloadManager.shared
        )
        
        addMenuItem(with: .decline, title: "Cancel All", action: #selector(cancelAllDownloadTasks))
        updateTasks()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}

// MARK: - Action

extension DownloadsInterfaceController {
    
    @objc
    private func cancelAllDownloadTasks() {
        for task in tasks {
            task.cancel()
        }
    }
}

// MARK: - Update

extension DownloadsInterfaceController {
    
    @objc
    private func handleTaskUpdates() {
        DispatchQueue.main.async {
            self.updateTasks()
        }
    }
    
    private func updateTasks() {
        DownloadManager.shared.getCurrentTasks { [weak self] tasks in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.tasks = tasks
            DispatchQueue.main.async {
                strongSelf.updateTable()
            }
        }
    }
    
    private func updateTable() {
        tasksTable.setNumberOfRows(tasks.count, withRowType: "DownloadTask")
        
        for (idx, task) in tasks.enumerated() {
            let rowController = tasksTable.rowController(at: idx) as! DownloadTaskRowController
            rowController.configure(with: task)
        }
    }
}
