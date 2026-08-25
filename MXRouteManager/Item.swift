//
//  Item.swift
//  MXRouteManager
//
//  Created by Nathan Pond on 8/25/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
