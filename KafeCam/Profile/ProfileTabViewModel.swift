//
// ProfileTabViewModel.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation
import SwiftUI

@MainActor
final class ProfileTabViewModel: ObservableObject {
	@AppStorage("displayName") private var displayNameAS: String = ""
	@Published var displayName: String = ""
	@Published var initials: String = ""
	@Published var email: String? = nil
	@Published var phone: String? = nil
	@Published var organization: String? = nil
	
	func load() async {
		do {
			let p = try await ProfilesRepository().getCurrent()
			displayName = p.name ?? ""
			initials = Self.makeInitials(from: p.name)
			email = p.email
			phone = p.phone
			organization = p.organization
			// keep Home header in sync
			let first = (p.name ?? "").split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
			displayNameAS = first.isEmpty ? (p.name ?? "") : first
		} catch {
			// ignore for now
		}
	}
	
	func logout() {
		// clear app storage and attempt signout
		displayNameAS = ""
		Task { try? await SupaAuthService.signOut() }
	}
	
	private static func makeInitials(from name: String?) -> String {
		guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return "" }
		let parts = name.split(separator: " ")
		let first = parts.first?.first.map(String.init) ?? ""
		let second = parts.dropFirst().first?.first.map(String.init) ?? ""
		return (first + second).uppercased()
	}
}
