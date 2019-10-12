//
//  KeychainServices.swift
//  Apollo
//
//  Created by Khaos Tian on 10/6/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import Security

class KeychainServices {
    
    static let shared = KeychainServices()
    
    private var cachedDevicePublicKey: Data?
    
    private(set) var deviceKey: SecKey? {
        didSet {
            cachedDevicePublicKey = getDevicePublicKeyData()
        }
    }
    
    private init() {
        initializeDeviceKey()
    }
}

// MARK: - Device Key

extension KeychainServices {
    
    var deviceKeyPublicKeyData: Data? {
        return cachedDevicePublicKey
    }
    
    private func initializeDeviceKey() {
        if let key = queryDeviceKey() {
            deviceKey = key
            return
        }
        
        deviceKey = createDeviceKey()
    }
    
    private func getDevicePublicKeyData() -> Data? {
        guard let key = deviceKey else {
            return nil
        }
        
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            return nil
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
            return nil
        }
        
        return publicKeyData as Data
    }
    
    private func queryDeviceKey() -> SecKey? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrApplicationLabel: Constants.deviceKeyLabel,
            kSecReturnRef: true
        ]
        
        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)
        
        if let key = item {
            return (key as! SecKey)
        }
        
        return nil
    }
    
    private func createDeviceKey() -> SecKey? {
        let key = SecKeyCreateRandomKey(deviceKeyAttributes, nil)
        
        if let key = key {
            return key
        }
        
        return nil
    }
    
    private var deviceKeyAttributes: CFDictionary {
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, .privateKeyUsage, nil)

        #if targetEnvironment(simulator)
        let attributes: [CFString : Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationLabel: Constants.deviceKeyLabel,
                kSecAttrAccessControl: access!
            ]
        ]
        #else
        let attributes: [CFString : Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationLabel: Constants.deviceKeyLabel,
                kSecAttrAccessControl: access!
            ]
        ]
        #endif
        
        return attributes as CFDictionary
    }
}

// MARK: - Decryption

extension KeychainServices {
    
    func decrypt(_ data: Data) -> Data? {
        guard let deviceKey = deviceKey else {
            return nil
        }
        
        let decryptedData = SecKeyCreateDecryptedData(deviceKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, data as CFData, nil)
        
        if let decryptedData = decryptedData {
            return decryptedData as Data
        }
        
        return nil
    }
}

// MARK: - Constants

extension KeychainServices {
    
    private struct Constants {
        static let deviceKeyLabel = "app.awas.Apollo.device.key"
    }
}
