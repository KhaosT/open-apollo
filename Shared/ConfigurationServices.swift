//
//  ConfigurationServices.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import Security
import SpotifyServices

class ConfigurationServices {
    
    static let shared = ConfigurationServices()
    
    var currentConfiguration: ServiceConfiguration? {
        didSet {
            updateCurrentConfiguration(currentConfiguration)
        }
    }
    
    init() {
        currentConfiguration = getCurrentConfiguration()
    }
}

// MARK: - Configuration

extension ConfigurationServices {
    
    private func getCurrentConfiguration() -> ServiceConfiguration? {
        guard let data = getCurrentConfigurationData() else {
            return nil
        }
        
        do {
            let configuration = try JSONDecoder().decode(ServiceConfiguration.self, from: data)
            return configuration
        } catch {
            NSLog("Configuration Decode Error: \(error)")
            return nil
        }
    }
    
    private func getCurrentConfigurationData() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.appConfigurationKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnRef as String: true,
            kSecReturnData as String: true
        ]
        
        var results: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &results)
        
        guard status == errSecSuccess, let credential = results as? [String: Any] else {
            return nil
        }
        
        guard let data = credential[kSecValueData as String] as? Data else  {
            return nil
        }
        
        return data
    }
    
    private func updateCurrentConfiguration(_ configuration: ServiceConfiguration?) {
        guard let configuration = configuration else {
            deleteCurrentConfiguration()
            return
        }
        
        do {
            let data = try JSONEncoder().encode(configuration)
            saveCurrentConfigurationData(data)
        } catch {
            NSLog("Configuration Encode Error: \(error)")
        }
    }
    
    private func saveCurrentConfigurationData(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.appConfigurationKey
        ]
        
        let fetchStatus = SecItemCopyMatching(query as CFDictionary, nil)
        
        if fetchStatus == errSecSuccess {
            SecItemUpdate(
                query as CFDictionary,
                [
                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                    kSecValueData as String: data
                ] as CFDictionary
            )
        } else {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: Constants.appConfigurationKey,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecValueData as String: data
            ]
            
            var addResult: CFTypeRef?
            SecItemAdd(addQuery as CFDictionary, &addResult)
        }
    }
    
    private func deleteCurrentConfiguration() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Constants.appConfigurationKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Constants

extension ConfigurationServices {
    
    private struct Constants {
        static let appConfigurationKey = "app.awas.Apollo.app_configuration"
    }
}
