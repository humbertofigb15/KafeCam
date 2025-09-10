//
//  HistoryModel.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 09/09/25.
//
import SwiftUI
import Foundation

struct PhotoRecord: Identifiable, Hashable {
    var id: UUID = UUID()
    let disease: String
    var imageName: String
    var date: String
    let location: String?
}

// Data ejemplo para Sprint 1
let sampleHistory: [PhotoRecord] = [
    .init(disease: "Roya", imageName: "Roya", date: "9 sep 2025", location: "Hectárea 1"),
    .init(disease: "Broca", imageName: "Broca", date: "8 sep 2025", location: "Hectárea 5"),
    .init(disease: "Deficiencia de Hierro", imageName: "Hierro", date: "7 sep 2025", location: "Hectárea 1"),
    .init(disease: "Deficiencia de Potasio", imageName: "Potasio", date: "5 sep 2025", location: "Hectárea 3")
]

