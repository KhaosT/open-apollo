//
//  Logging.swift
//  Apollo
//
//  Created by Khaos Tian on 9/29/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public class LogConfiguration {
    
    public typealias Logger = ((String) -> Void)
    
    private static var logger: Logger?
    
    public static func configure(_ logger: @escaping Logger) {
        self.logger = logger
    }
    
    internal static func log(_ message: String) {
        if let logger = logger {
            logger(message)
        } else {
            NSLog(message)
        }
    }
}

internal func log(_ message: String) {
    LogConfiguration.log(message)
}

public protocol ExternalLogger {
    
    func log(_ message: String)
}
