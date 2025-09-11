//
//  RegisterView.swift
//  Register
//
//  Created by Guillermo Lira on 10/09/25.
//




import SwiftUI

struct RegisterView: View {
    @ObservedObject var vm: RegisterViewModel
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 88/255, green: 129/255, blue: 87/255)
    private let darkColor   = Color(red: 82/255,  green: 76/255,  blue: 41/255)

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundColor(accentColor)

                Text("Create account")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(accentColor)

                Text("Register with your details")
                    .foregroundColor(darkColor)

                AuthCard {
                    // Name
                    ktextfild(title: "Name", text: $vm.name, keyboard: .default, contentType: .name)
                    if let e = vm.nameError { Text(e).font(.caption).foregroundColor(.red) }

                    // Email (optional)
                    ktextfild(title: "Email (optional)", text: $vm.email, keyboard: .emailAddress, contentType: .emailAddress)
                    if let e = vm.emailError { Text(e).font(.caption).foregroundColor(.red) }

                    // Phone
                    ktextfild(title: "Phone (10 digits)", text: $vm.phone, keyboard: .numberPad, contentType: .telephoneNumber)
                    if let e = vm.phoneError { Text(e).font(.caption).foregroundColor(.red) }

                    // Password
                    ktextfild(title: "Password", text: $vm.password, isSecure: true, keyboard: .default, contentType: .password)
                    if let e = vm.passwordError { Text(e).font(.caption).foregroundColor(.red) }

                    // Organization (fixed Kaapeh, disabled)
                    ktextfild(title: "Organization", text: $vm.organization, isSecure: false, keyboard: .default, contentType: .organizationName, isDisabled: true)

                    Button("Create Account") {
                        if vm.submit() { dismiss() }
                    }
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
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(false)
    }
}
