//
//  AnyPlaylist.swift
//  Apollo
//
//  Created by Khaos Tian on 11/3/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

public protocol AnyPlaylist {
    var id: String { get }
    var name: String { get }
    var images: [Image] { get }
}
