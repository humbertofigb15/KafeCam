//
//  HistoryStore.swift
//  KafeCam
//
//  Created by Humberto Figueroa on 01/10/25.
//

import SwiftUI

struct HistoryEntry: Identifiable {
    let id = UUID()
    let image: UIImage
    let prediction: String
    let date: Date = Date()
}

class HistoryStore: ObservableObject {
    @Published var entries: [HistoryEntry] = []
    
    func add(image: UIImage, prediction: String) {
        let entry = HistoryEntry(image: image, prediction: prediction)
        entries.append(entry)
    }
}

