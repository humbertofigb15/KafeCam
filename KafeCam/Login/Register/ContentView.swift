//
//  ContentView.swift
//  Register
//
//  Created by Guillermo Lira on 10/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionViewModel(auth: LocalAuthService())

    var body: some View {
        if session.isLoggedIn {
            HomeView() // <- tu pantalla existente
                .toolbar {
                    Button("Logout") { session.logout() }
                }
        } else {
            // Inyectamos session en el VM del login
            LoginView(vm: LoginViewModel(auth: session.auth, session: session))
        }
    }
}

#Preview { ContentView() }
