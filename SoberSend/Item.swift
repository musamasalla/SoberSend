//
//  Item.swift
//  SoberSend
//
//  Created by Musa Masalla on 2026/02/26.
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
