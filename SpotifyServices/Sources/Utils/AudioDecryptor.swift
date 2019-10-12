//
//  AudioDecryptor.swift
//  Apollo
//
//  Created by Khaos Tian on 10/6/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import CommonCrypto

class AudioDecryptor {
    
    private var cryptor: CCCryptorRef?
    
    init?(keyData: Data) {
        var key = [UInt8](keyData)
        var iv = Constants.iv
        
        let status = CCCryptorCreateWithMode(
            CCOperation(kCCDecrypt),
            CCMode(kCCModeCTR),
            CCAlgorithm(kCCAlgorithmAES),
            0,
            &iv,
            &key,
            key.count,
            nil,
            0,
            0,
            CCModeOptions(kCCModeOptionCTR_BE),
            &cryptor
        )
        
        if status != kCCSuccess {
            return nil
        }
    }
    
    // TODO: Support Jumping block
    
    func decrypt(_ data: Data) throws -> Data {
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: data.count, alignment: 0)
        var outputSize = 0
        
        try data.withUnsafeBytes { ptr -> Void in
            let ret = CCCryptorUpdate(self.cryptor, ptr.baseAddress, ptr.count, buffer, ptr.count, &outputSize)
            guard ret == kCCSuccess else {
                throw AudioDecryptor.Error.internalError(Int(ret))
            }
        }
        
        let decodedData = Data(bytes: buffer, count: outputSize)
        buffer.deallocate()
        return decodedData
    }
    
    deinit {
        CCCryptorRelease(cryptor)
        cryptor = nil
    }
}

// MARK: - Constants

extension AudioDecryptor {
    
    private struct Constants {
        static let iv: [UInt8] = [0x72, 0xe0, 0x67, 0xfb, 0xdd, 0xcb, 0xcf, 0x77, 0xeb, 0xe8, 0xbc, 0x64, 0x3f, 0x63, 0x0d, 0x93]
    }
}

// MARK: - Error

extension AudioDecryptor {
    
    public enum Error: Swift.Error {
        case internalError(Int)
    }
}
