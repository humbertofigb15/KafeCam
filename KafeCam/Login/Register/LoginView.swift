//
//  LoginView.swift
//  Register
//
//  Created by Guillermo Lira on 10/09/25.
//
import SwiftUI

struct LoginView: View {
    @ObservedObject var vm: LoginViewModel
    @State private var goRegister = false

    // Palette
    private let accentColor = Color(red: 88/255, green: 129/255, blue: 87/255)
    private let darkColor   = Color(red: 82/255,  green: 76/255,  blue: 41/255)

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    // Leaf icon on top
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor)

                    Text("Welcome back")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(accentColor)

                    Text("Sign in to continue")
                        .foregroundColor(darkColor)

                    AuthCard {
                        // Phone
                        ktextfild(title: "Phone (10 digits)",
                                  text: $vm.phone,
                                  keyboard: .numberPad,
                                  contentType: .telephoneNumber)
                        if let err = vm.phoneError {
                            Text(err).font(.caption).foregroundColor(.red)
                        }

                        // Password
                        ktextfild(title: "Password",
                                  text: $vm.password,
                                  isSecure: true,
                                  keyboard: .default,
                                  contentType: .password)
                        if let err = vm.passwordError {
                            Text(err).font(.caption).foregroundColor(.red)
                        }

                        // Apple-like button
                        Button("Sign In", action: vm.submit)
                            .buttonStyle(.borderedProminent)
                            .tint(accentColor)
                            .buttonBorderShape(.roundedRectangle(radius: 14))
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if vm.isLoading { ProgressView().tint(.white) }
                            }
                            .disabled(vm.isLoading)
                    }

                    HStack(spacing: 6) {
                        Text("No account?")
                        Button("Create one") { goRegister = true }
                            .foregroundColor(accentColor)
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationDestination(isPresented: $goRegister) {
                // Pass the same auth & session to Register
                RegisterView(vm: RegisterViewModel(auth: vm.auth, session: vm.session))
            }
        }
        .alert("Account created", isPresented: $vm.signupJustSucceeded) {
            Button("OK") { vm.signupJustSucceeded = false }
        } message: {
            Text("Sign in using your 10-digit code and password.")
        }
    }
}
