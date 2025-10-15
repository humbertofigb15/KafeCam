//
//  HistoryEntry.swift
//  KafeCam
//
//  Created by Humberto Figueroa on 15/10/25.
//

import SwiftUI

struct HistoryEntry: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let prediction: String
    let date: Date
    var isFavorite: Bool = false
}
