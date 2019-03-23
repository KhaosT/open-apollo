//
//  Array+SpotifyImage.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/28/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import UIKit
import SpotifyServices

extension Array where Element == Image {
    
    func preferredImage(matchingWidth: CGFloat) -> Image? {
        guard !isEmpty else {
            return nil
        }
        
        var selectedImage: Image?
        var distance: Double = .greatestFiniteMagnitude
        
        for image in self {
            if let width = image.width {
                let difference = width - Double(matchingWidth)
                
                guard difference > 0 else {
                    continue
                }
                
                if difference < distance {
                    selectedImage = image
                    distance = difference
                }
            } else {
                selectedImage = image
                distance = .greatestFiniteMagnitude
            }
        }
        
        return selectedImage
    }
}
