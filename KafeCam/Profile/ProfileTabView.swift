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
                            Text(vm.displayName.isEmpty ? "—" : vm.displayName).font(.headline)
                            if let email = vm.email, !email.isEmpty { Text(email).foregroundStyle(.secondary) }
                        }
                    }
                } header: {
                    Text("Cuenta").foregroundStyle(accentColor)
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
                    if let role = vm.role {
                        LabeledContent("Rol", value: role.capitalized)
                    }
                    if let tname = vm.technicianName, !tname.isEmpty {
                        LabeledContent("Técnico", value: tname)
                    }
                    if !(vm.incomingRequests.isEmpty) {
                        NavigationLink {
                            RequestsInboxView(requests: vm.incomingRequests)
                        } label: {
                            Label("Peticiones", systemImage: "tray.full.fill").foregroundStyle(accentColor)
                        }
                    }
                    // TODO (future): Edit profile fields and upload avatar
                    if vm.canManageFarmers {
                        NavigationLink {
                            FarmersListView()
                        } label: {
                            Label("Farmers", systemImage: "person.3.fill").foregroundStyle(accentColor)
                        }
                    }
                } header: {
                    Text("Detalles").foregroundStyle(accentColor)
                }
                Section {
                    NavigationLink {
                        ChangePasswordView()
                    } label: {
                        Label("Cambiar contraseña", systemImage: "key.fill").foregroundStyle(accentColor)
                    }
                    Button(role: .destructive) {
                        vm.logout()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right").foregroundStyle(accentColor)
                    }
                }
            }
            .navigationTitle("Perfil")
            // Editar perfil oculto temporalmente
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
