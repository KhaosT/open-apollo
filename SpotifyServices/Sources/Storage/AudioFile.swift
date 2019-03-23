//
//  AudioFile.swift
//  Apollo
//
//  Created by Khaos Tian on 10/27/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

class AudioFile {
    
    private let storageLocation: URL
    private let fileInfo: TrackFileInfo
    private let audioKeyData: Data
    private var audioDecryptor: AudioDecryptor
    
    private var expectedLength: UInt64 = 0
    
    private(set) var isCompleted = false
    
    private var readHandler: FileHandle?
    private var writeHandler: FileHandle?
    
    private let operationQueue = DispatchQueue(label: "app.awas.Apollo.audioFile")
    
    static func isLocallyAvailable(for fileInfo: TrackFileInfo) -> Bool {
        if FileManager.default.fileExists(atPath: LocalStorageManager.shared.audioFileStorageLocation(for: .download).appendingPathComponent(fileInfo.fileId).path) {
            return true
        } else if FileManager.default.fileExists(atPath: LocalStorageManager.shared.audioFileStorageLocation(for: .temporary).appendingPathComponent(fileInfo.fileId).path) {
            return true
        }
        
        return false
    }
    
    static func storageLocation(for fileInfo: TrackFileInfo) -> URL {
        let downloadAudioFileStorageLocation = LocalStorageManager.shared.audioFileStorageLocation(for: .download)
        if FileManager.default.fileExists(atPath: downloadAudioFileStorageLocation.appendingPathComponent(fileInfo.fileId).path) {
            return downloadAudioFileStorageLocation
        } else {
            return LocalStorageManager.shared.audioFileStorageLocation(for: .temporary)
        }
    }
    
    init?(_ storageLocation: URL, fileInfo: TrackFileInfo, audioKeyData: Data) {
        self.storageLocation = storageLocation
        self.fileInfo = fileInfo
        self.audioKeyData = audioKeyData
        
        guard let decryptor = AudioDecryptor(keyData: audioKeyData) else {
            return nil
        }
        
        self.audioDecryptor = decryptor
        
        if FileManager.default.fileExists(atPath: storageLocation.appendingPathComponent(fileInfo.fileId).path) {
            do {
                let targetUrl = storageLocation.appendingPathComponent(fileInfo.fileId)
                readHandler = try FileHandle(forReadingFrom: targetUrl)
                expectedLength = (try FileManager.default.attributesOfItem(atPath: targetUrl.path))[.size] as? UInt64 ?? 0
                isCompleted = true
            } catch {
                NSLog("Error: \(error)")
            }
        } else if FileManager.default.fileExists(atPath: storageLocation.appendingPathComponent(fileInfo.fileId + Constants.partialKey).path) {
            let targetUrl = storageLocation.appendingPathComponent(fileInfo.fileId + Constants.partialKey)
            do {
                readHandler = try FileHandle(forReadingFrom: targetUrl)
                writeHandler = try FileHandle(forWritingTo: targetUrl)
                writeHandler?.seekToEndOfFile()
                isCompleted = false
            } catch {
                NSLog("Error: \(error)")
            }
        } else {
            let targetUrl = storageLocation.appendingPathComponent(fileInfo.fileId + Constants.partialKey)
            FileManager.default.createFile(atPath: targetUrl.path, contents: nil, attributes: nil)
            do {
                readHandler = try FileHandle(forReadingFrom: targetUrl)
                writeHandler = try FileHandle(forWritingTo: targetUrl)
                isCompleted = false
            } catch {
                NSLog("Error: \(error)")
            }
        }
    }
    
    deinit {
        readHandler?.closeFile()
        writeHandler?.closeFile()
    }
}

// MARK: - Read

extension AudioFile {
    
    func resetAudioFileReadProgress() {
        operationQueue.sync {
            guard let decryptor = AudioDecryptor(keyData: audioKeyData) else {
                return
            }
            
            self.audioDecryptor = decryptor
            self.readHandler?.seek(toFileOffset: 0)
        }
    }
    
    func read(into buffer: UnsafeMutableRawPointer, size: Int, count: Int) -> Int {
        return operationQueue.sync {
            guard let readHandler = readHandler else {
                return 0
            }
            
            guard currentAvailableLength > Constants.headerLength else {
                return 0
            }
            
            let availableLength = currentAvailableLength - currentReadOffset
            guard availableLength > 0 else {
                return 0
            }
            
            var shouldRemoveHeaderFromResult = false
            if currentReadOffset < Constants.headerLength {
                shouldRemoveHeaderFromResult = true
            }
            
            let readLength = min(size * count, Int(availableLength))
            let data = readHandler.readData(ofLength: readLength)
            
            let decryptedData: Data
            do {
                decryptedData = try audioDecryptor.decrypt(data)
            } catch {
                log("Decrypt Error: \(error)")
                NSLog("Decrypt Error: \(error)")
                return 0
            }
            
            if shouldRemoveHeaderFromResult {
                decryptedData.copyBytes(to: buffer.assumingMemoryBound(to: UInt8.self), from: Int(Constants.headerLength)..<readLength)
                return readLength - Int(Constants.headerLength)
            } else {
                decryptedData.copyBytes(to: buffer.assumingMemoryBound(to: UInt8.self), from: 0..<readLength)
                return readLength
            }
        }
    }
}

// MARK: - Write

extension AudioFile {
    
    func updateExpectedLength(_ length: UInt64, isIncremental: Bool) {
        operationQueue.sync {
            if isIncremental {
                self.expectedLength = currentWriteOffset + length
            } else {
                self.expectedLength = length
            }
        }
    }
    
    func write(_ data: Data) {
        operationQueue.sync {
            writeHandler?.write(data)
        }
    }
}

// MARK: - Completion Migration

extension AudioFile {
    
    func finalizeFile() {
        operationQueue.sync {
            migrateFileAndReopenFileHandlers()
        }
    }
    
    private func migrateFileAndReopenFileHandlers() {
        let currentOffset = currentReadOffset
        
        readHandler?.closeFile()
        writeHandler?.closeFile()
        
        readHandler = nil
        writeHandler = nil
        
        let originUrl = storageLocation.appendingPathComponent(fileInfo.fileId + Constants.partialKey)
        let targetUrl = storageLocation.appendingPathComponent(fileInfo.fileId)
        
        do {
            try FileManager.default.moveItem(at: originUrl, to: targetUrl)
            expectedLength = (try FileManager.default.attributesOfItem(atPath: targetUrl.path))[.size] as? UInt64 ?? 0
            readHandler = try FileHandle(forReadingFrom: targetUrl)
            readHandler?.seek(toFileOffset: currentOffset)
        } catch {
            fatalError("Unexpect error occus when moving audio file, \(error)")
        }
        
        isCompleted = true
    }
}

// MARK: - Download Migration

extension AudioFile {
    
    static func migrateDownloadedAudioFile(_ fileId: String, fromLocation location: URL) {
        let targetLocation = LocalStorageManager.shared.audioFileStorageLocation(for: .download).appendingPathComponent(fileId)
        
        do {
            try FileManager.default.moveItem(at: location, to: targetLocation)
        } catch {
            NSLog("[Download] Unexpect error occus when moving audio file, \(error)")
        }
    }
}

// MARK: - Helper

extension AudioFile {
    
    private var currentReadOffset: UInt64 {
        return readHandler?.offsetInFile ?? 0
    }
    
    private var currentWriteOffset: UInt64 {
        return writeHandler?.offsetInFile ?? 0
    }
    
    private var currentAvailableLength: UInt64 {
        if writeHandler != nil {
            return currentWriteOffset
        } else {
            return expectedLength
        }
    }
    
    var availableLength: UInt64 {
        return operationQueue.sync {
            return currentAvailableLength
        }
    }
    
    var readOffset: UInt64 {
        return operationQueue.sync {
            return currentReadOffset
        }
    }
}

// MARK: - Constants

extension AudioFile {
    
    private struct Constants {
        static let partialKey = ".partial"
        static let headerLength: UInt64 = 167
    }
}
