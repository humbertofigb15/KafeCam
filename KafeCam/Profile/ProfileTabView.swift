//
// ProfileTabView.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import SwiftUI

struct ProfileTabView: View {
	@StateObject private var vm = ProfileTabViewModel()
	
	var body: some View {
		NavigationStack {
			Form {
				Section("Account") {
					HStack {
						AvatarView(initials: vm.initials)
						VStack(alignment: .leading) {
							Text(vm.displayName).font(.headline)
							if let email = vm.email, !email.isEmpty { Text(email).foregroundStyle(.secondary) }
						}
					}
				}
				Section("Details") {
					LabeledContent("Phone", value: vm.phone ?? "—")
					LabeledContent("Organization", value: vm.organization ?? "—")
				}
				Section {
					Button("Logout", role: .destructive) { vm.logout() }
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
