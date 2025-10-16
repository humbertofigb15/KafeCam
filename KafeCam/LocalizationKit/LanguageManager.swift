//
//  LanguageManager.swift
//  KafeCam
//
//  Created by Guillermo Lira on 15/10/25.
//


import SwiftUI
import Combine

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") var appLanguage: String = "es" {
        didSet { objectWillChange.send() }
    }

    var currentLocale: Locale {
        // Para lookup de Bundle usamos códigos: "es", "en", "tzo"
        Locale(identifier: appLanguage)
    }

    // Soporte para títulos/labels del picker
    let supported: [(code: String, name: String)] = [
        ("es", "Español"),
        ("en", "English"),
        ("tzo", "Tzotzil (beta)")
    ]
}
