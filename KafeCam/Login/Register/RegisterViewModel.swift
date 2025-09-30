//
//  RegisterViewModel.swift
//  Register
//
//  Created by Guillermo Lira on 10/09/25.
//


import Foundation

final class RegisterViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var organization: String = "Kaapeh"

    @Published var nameError: String? = nil
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
        nameError = nil; emailError = nil; phoneError = nil; passwordError = nil
        isLoading = true
        defer { isLoading = false }

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = AuthError.invalidName.errorDescription; return false
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
            try auth.register(name: name, email: email.isEmpty ? nil : email,
                              phone: phone, password: password, organization: organization)
            // Do NOT auto-login; signal success so Login can show a confirmation
            UserDefaults.standard.set(true, forKey: "signupSuccess")
            return true
        } catch let err as AuthError {
            switch err {
            case .duplicatePhone: phoneError = err.errorDescription
            case .invalidName:    nameError = err.errorDescription
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
