//
//  Listable.swift
//  Apollo
//
//  Created by Khaos Tian on 11/4/18.
//  Copyright © 2018 Oltica. All rights reserved.
//

import Foundation

class ListableSection<T: Equatable> {
    var header: String?
    var footer: String?
    
    var associatedRows = [ListableRow<T>]()
}

class ListableRow<T: Equatable> {
    var title: String?
    var rowType: T
    var preferedCellIdentifier: String
    var content: Any?
    
    init(type: T, title: String?, cellIdentifier: String, content: Any? = nil) {
        self.rowType = type
        self.title = title
        self.preferedCellIdentifier = cellIdentifier
        self.content = content
    }
}
