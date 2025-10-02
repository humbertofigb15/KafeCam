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
	@Published var role: String? = nil
    @Published var incomingRequests: [AssignmentRequestDTO] = []
    @Published var technicianName: String? = nil
	
	var canManageFarmers: Bool { (role == "technician") || (role == "admin") }
	
	func load() async {
		do {
			let userId = try await SupaAuthService.currentUserId()
			print("[ProfileTabVM] Loading profile for User ID: \(userId)")
			
			let repo = ProfilesRepository()
			let p = try await repo.getOrCreateCurrent()
			
			print("[ProfileTabVM] Profile loaded - Name: \(p.name ?? "nil"), Phone: \(p.phone ?? "nil"), Email: \(p.email ?? "nil"), Org: \(p.organization ?? "nil"), Role: \(p.role ?? "nil")")
			
			displayName = p.name ?? ""
			initials = Self.makeInitials(from: p.name)
			email = p.email
			phone = p.phone
			organization = p.organization
			role = p.role
			
			// Keep Home header in sync
			let fullName = p.name ?? ""
			let firstName = fullName.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? fullName
			displayNameAS = firstName
			
			print("[ProfileTabVM] Display values set - DisplayName: \(displayName), FirstName: \(firstName), Initials: \(initials)")

            // Farmer: load incoming requests
            if (p.role == "farmer") {
                incomingRequests = try await AssignmentRequestsRepository().listIncoming()
                // Load assigned technician(s)
                struct Row: Codable { let id: UUID; let name: String? }
                #if canImport(Supabase)
                let techs: [Row] = try await SupaClient.shared
                    .rpc("list_technicians_for_current_farmer")
                    .execute().value
                technicianName = techs.first?.name
                #else
                technicianName = nil
                #endif
            } else {
                incomingRequests = []
                technicianName = nil
            }
		} catch {
			print("[ProfileTabVM] Error loading profile: \(error)")
		}
	}
	
	func logout() {
		// clear app storage and sign out, then flip session flag back to login if available
		displayNameAS = ""
		Task { try? await SupaAuthService.signOut() }
		NotificationCenter.default.post(name: .init("kafe.session.logout"), object: nil)
	}
	
	private static func makeInitials(from name: String?) -> String {
		guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return "" }
		let parts = name.split(separator: " ")
		let first = parts.first?.first.map(String.init) ?? ""
		let second = parts.dropFirst().first?.first.map(String.init) ?? ""
		return (first + second).uppercased()
	}
}
