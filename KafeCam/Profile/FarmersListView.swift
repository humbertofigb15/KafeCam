//
// FarmersListView.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import SwiftUI

struct FarmersListView: View {
    @StateObject private var vm = FarmersListViewModel()
    let accentColor  = Color(red: 88/255, green: 129/255, blue: 87/255)
    let darkColor    = Color(red: 82/255,  green: 76/255,  blue: 41/255)
    
    var body: some View {
        List(vm.farmers) { f in
            VStack(alignment: .leading, spacing: 2) {
                Text(f.name ?? "(no name)")
                    .font(.headline)
                if let phone = f.phone { Text(phone).font(.subheadline).foregroundStyle(.secondary) }
                if let email = f.email { Text(email).font(.subheadline).foregroundStyle(.secondary) }
            }
        }
        .overlay { if vm.isLoading { ProgressView() } }
        .navigationTitle(Text("Farmers").foregroundStyle(accentColor))
        .task { vm.load() }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: { Text(vm.errorMessage ?? "") }
    }
}

#Preview {
    FarmersListView()
}
