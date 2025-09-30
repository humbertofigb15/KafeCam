//
//  LoginViewModel.swift
//  Register
//
//  Created by Guillermo Lira on 10/09/25.
//


import Foundation

final class LoginViewModel: ObservableObject {
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var phoneError: String? = nil
    @Published var passwordError: String? = nil   // generic error shown under password
    @Published var isLoading = false
    @Published var signupJustSucceeded = false

    let auth: AuthService
    let session: SessionViewModel

    init(auth: AuthService, session: SessionViewModel) {
        self.auth = auth
        self.session = session
        // one-time flag to inform user after returning from signup
        if UserDefaults.standard.bool(forKey: "signupSuccess") {
            self.signupJustSucceeded = true
            UserDefaults.standard.removeObject(forKey: "signupSuccess")
        }
    }

    func submit() {
        phoneError = nil
        passwordError = nil
        isLoading = true
        defer { isLoading = false }

        // Validate
        guard LocalAuthService.validatePhone(phone) else {
            phoneError = AuthError.invalidPhone.errorDescription
            return
        }
        guard !password.isEmpty else {
            passwordError = "Password cannot be empty."
            return
        }

        // Try login
        do {
            try auth.login(phone: phone, password: password)
            session.isLoggedIn = true
        } catch {
            // generic on purpose
            passwordError = AuthError.userNotFoundOrBadPassword.errorDescription
        }
    }
}
