//
//  RegisterViewModel.swift
//  Register
//
//  Created by Guillermo Lira on 10/09/25.
//


import Foundation

final class RegisterViewModel: ObservableObject {
    // Split name fields for greeting "Hola {Nombres}"
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var organization: String = "Kaapeh"

    @Published var firstNameError: String? = nil
    @Published var lastNameError: String? = nil
    @Published var emailError: String? = nil
    @Published var phoneError: String? = nil
    @Published var passwordError: String? = nil
    @Published var isLoading = false

    let auth: AuthService
    let session: SessionViewModel           // <- NUEVO

    init(auth: AuthService, session: SessionViewModel) {
        self.auth = auth
        self.session = session
    }

    func submit() -> Bool {
        firstNameError = nil; lastNameError = nil; emailError = nil; phoneError = nil; passwordError = nil
        isLoading = true
        defer { isLoading = false }

        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            firstNameError = AuthError.invalidName.errorDescription; return false
        }
        // Last name optional but keep for completeness; validate minimal length if provided
        if !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && lastName.count < 2 {
            lastNameError = "Apellido muy corto"; return false
        }
        if !email.isEmpty && !LocalAuthService.validateEmail(email) {
            emailError = AuthError.invalidEmail.errorDescription; return false
        }
        if !LocalAuthService.validatePhone(phone) {
            phoneError = AuthError.invalidPhone.errorDescription; return false
        }
        if !LocalAuthService.validatePassword(password) {
            passwordError = AuthError.weakPassword.errorDescription; return false
        }

        do {
            let fullName = lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? firstName : "\(firstName) \(lastName)"
            print("[RegisterVM] Registering with Name: \(fullName), Phone: \(phone), Email: \(email.isEmpty ? "none" : email), Org: \(organization)")
            try auth.register(name: fullName, email: email.isEmpty ? nil : email,
                              phone: phone, password: password, organization: organization)
            // Do NOT auto-login; signal success so Login can show a confirmation
            UserDefaults.standard.set(true, forKey: "signupSuccess")
            print("[RegisterVM] Registration successful")
            return true
        } catch let err as AuthError {
            switch err {
            case .duplicatePhone: phoneError = err.errorDescription
            case .invalidName:    firstNameError = err.errorDescription
            case .invalidEmail:   emailError = err.errorDescription
            case .invalidPhone:   phoneError = err.errorDescription
            case .weakPassword:   passwordError = err.errorDescription
            default:              passwordError = "Something went wrong. Please try again."
            }
            return false
        } catch {
            passwordError = "Something went wrong. Please try again."
            return false
        }
    }
}
