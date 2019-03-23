//
//  VorbisDecoder.swift
//  Apollo
//
//  Created by Khaos Tian on 9/30/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation
import AVFoundation
import Vorbis

class VorbisDecoder {
    
    private var audioFile = OggVorbis_File()
    private var audioFormat: AVAudioFormat!
    
    private var isReady = false
    private var hasEnded = false
    
    private var didFinishLoading = false
    private var dataSource: AudioFile
    
    private let queue = DispatchQueue(label: "app.awas.AudioDecoder")
    
    init(audioFile: AudioFile) {
        dataSource = audioFile
    }
    
    deinit {
        ov_clear(&audioFile)
    }
    
    private func openVorbisFile() {
        ov_open_callbacks(
            &dataSource,
            &audioFile,
            nil,
            0,
            ov_callbacks(
                read_func: { (ptr, size, count, context) -> Int in
                    guard let ptr = ptr, let context = context?.assumingMemoryBound(to: AudioFile.self).pointee else {
                        fatalError()
                    }
                    
                    let n = context.read(into: ptr, size: size, count: count)
                    return n
                },
                seek_func: nil,
                close_func: nil,
                tell_func: nil
            )
        )
    }
    
    public func handleAudioFileUpdate() {
        queue.async {
            self._handleAudioFileUpdate()
        }
    }
    
    private func _handleAudioFileUpdate() {
        if !isReady, dataSource.availableLength >= 8192 {
            isReady = true
            openVorbisFile()
        }
    }
    
    public func read(into buffer: inout AVAudioPCMBuffer?) throws -> ReadResult {
        return try queue.sync {
            return try self._read(into: &buffer)
        }
    }
    
    private func _read(into buffer: inout AVAudioPCMBuffer?) throws -> ReadResult {
        guard isReady else {
            throw Error.notEnoughBuffer
        }
        
        if audioFormat == nil {
            guard let infoContainer = ov_info(&audioFile, -1) else {
                throw Error.notEnoughBuffer
            }
            
            let info = infoContainer.pointee
            
            audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: Double(info.rate),
                channels: AVAudioChannelCount(info.channels),
                interleaved: false
            )!
        }
        
        guard !hasEnded else {
            return .eof
        }
        
        var bitstream: Int32 = 0
        
        var eof = false
        var shouldStop = false
        
        let pcm = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 32768)!
        var availableSpace = Int32(pcm.frameCapacity - pcm.frameLength)
        
        while !shouldStop, availableSpace > 0 {
            var buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>?
            let ret = ov_read_float(&audioFile, &buffer, availableSpace, &bitstream)
            
            switch ret {
            case 0:
                eof = true
                shouldStop = true
            case ..<0:
                NSLog("Internal Error: \(ret)")
                shouldStop = true
            default:
                let offset = Int(pcm.frameLength)
                
                for channel in 0..<audioFormat.channelCount {
                    let intChannel = Int(channel)
                    memcpy(pcm.floatChannelData![intChannel] + offset, buffer![intChannel]!, ret * MemoryLayout<Float32>.size)
                }
                pcm.frameLength = pcm.frameLength + AVAudioFrameCount(ret)
                availableSpace = Int32(pcm.frameCapacity - pcm.frameLength)
            }
        }
        
        guard pcm.frameLength > 0 else {
            if didFinishLoading {
                hasEnded = true
                return .eof
            } else {
                return .noFrameAvailable
            }
        }
        
        buffer = pcm
        return eof ? .eof : .normal
    }
    
    public func dataSourceDidFinishLoading() {
        didFinishLoading = true
        if !isReady {
            isReady = true
            openVorbisFile()
        }
    }
}

// MARK: - Read State

extension VorbisDecoder {
    
    public enum ReadResult {
        case normal
        case noFrameAvailable
        case eof
    }
}

// MARK: - Error

extension VorbisDecoder {
    
    public enum Error: Swift.Error {
        case notEnoughBuffer
        case internalError(Int)
    }
}
