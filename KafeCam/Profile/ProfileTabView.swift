//
// ProfileTabView.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//
import Foundation
import SwiftUI

struct ProfileTabView: View {
    @StateObject private var vm = ProfileTabViewModel()
    
    // Colores
    let accentColor  = Color(red: 88/255, green: 129/255, blue: 87/255)
    let darkColor    = Color(red: 82/255,  green: 76/255,  blue: 41/255)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        AvatarView(initials: vm.initials)
                        VStack(alignment: .leading) {
                            Text(vm.displayName).font(.headline)
                            if let email = vm.email, !email.isEmpty { Text(email).foregroundStyle(.secondary) }
                        }
                    }
                } header: {
                    Text("Account").foregroundStyle(accentColor)
                }
                Section {
                    LabeledContent {
                        Text(vm.phone ?? "—")
                    } label: {
                        Label {
                            Text("Teléfono")
                        } icon: {
                            Image(systemName: "phone.fill").foregroundStyle(accentColor)
                        }
                    }
                    LabeledContent {
                        Text(vm.organization ?? "—")
                    } label: {
                        Label {
                            Text("Organización")
                        } icon: {
                            Image(systemName: "leaf.fill").foregroundStyle(accentColor)
                        }
                    }
                } header: {
                    Text("Details").foregroundStyle(accentColor)
                }
                Section {
                    Button(role: .destructive) {
                        vm.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right").foregroundStyle(accentColor)
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .task { await vm.load() }
    }
}

private struct AvatarView: View {
    let initials: String
    var body: some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            Text(initials.isEmpty ? "" : initials)
                .font(.headline)
        }
        .frame(width: 48, height: 48)
    }
}
#Preview {
    ProfileTabView()
}
