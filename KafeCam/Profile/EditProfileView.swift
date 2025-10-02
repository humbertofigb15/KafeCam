//
// EditProfileView.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import SwiftUI

struct EditProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var organization: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss

    private let repo = ProfilesRepository()

    var body: some View {
        Form {
            Section("Nombres y apellidos") {
                TextField("Nombres", text: $firstName)
                    .textInputAutocapitalization(.words)
                TextField("Apellidos", text: $lastName)
                    .textInputAutocapitalization(.words)
            }
            Section("Contacto") {
                TextField("Correo", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Teléfono (10 dígitos)", text: $phone)
                    .keyboardType(.numberPad)
            }
            Section("Organización") {
                TextField("Organización", text: $organization)
            }
            if let e = errorMessage { Text(e).foregroundColor(.red) }
            Section {
                Button("Guardar cambios") { Task { await save() } }
                    .disabled(isSaving)
            }
        }
        .navigationTitle("Editar perfil")
        .task { await loadInitial() }
    }

    private func loadInitial() async {
        do {
            let p = try await repo.getOrCreateCurrent()
            let full = (p.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if full.isEmpty {
                firstName = ""
                lastName = ""
            } else {
                let parts = full.split(separator: " ")
                firstName = parts.first.map(String.init) ?? full
                lastName = parts.dropFirst().joined(separator: " ")
            }
            email = p.email ?? ""
            phone = p.phone ?? ""
            organization = p.organization ?? ""
        } catch {
            errorMessage = "No se pudo cargar el perfil"
        }
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let fullName = lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? firstName : "\(firstName) \(lastName)"
            _ = try await repo.upsertCurrentUserProfile(
                name: fullName,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                organization: organization.isEmpty ? nil : organization
            )
            // Keep Home header in sync immediately
            let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !first.isEmpty { UserDefaults.standard.set(first, forKey: "displayName") }
            dismiss()
        } catch {
            errorMessage = "No se pudo guardar"
        }
    }
}

#Preview { NavigationStack { EditProfileView() } }


