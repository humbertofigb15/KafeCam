//
//  KafeCamApp.swift
//  KafeCam
//

import SwiftUI

@main
struct KafeCamApp: App {
    @StateObject private var historyStore = HistoryStore()

    var body: some Scene {
        WindowGroup {
            HomeView() 
                .environmentObject(historyStore)
        }
    }
}
