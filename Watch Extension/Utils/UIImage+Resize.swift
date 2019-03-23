//
//  UIImage+Resize.swift
//  Watch Extension
//
//  Created by Khaos Tian on 10/7/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import WatchKit

extension UIImage {
    
    func resize(maxLength: CGFloat) -> UIImage? {
        let width: CGFloat
        let height: CGFloat
        
        if size.width <= size.height {
            width = maxLength
            let scale = width / size.width
            height = size.height * scale
        } else {
            height = maxLength
            let scale = height / size.height
            width = size.width * scale
        }
        
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: maxLength, height: maxLength), false, 0)
        self.draw(in: CGRect(x: 0.0, y: 0.0, width: maxLength, height: maxLength))
        
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
