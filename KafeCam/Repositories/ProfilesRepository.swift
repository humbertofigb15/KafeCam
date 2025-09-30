//
// ProfilesRepository.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct ProfilesRepository {
	#if canImport(Supabase)
	private struct UpsertProfilePayload: Encodable {
		let id: String
		let name: String?
		let email: String?
		let phone: String?
		let organization: String?
		let locale: String?
	}
	
	func upsertCurrentUserProfile(name: String?, email: String?, phone: String?, organization: String?) async throws -> ProfileDTO {
		let userId = try await SupaAuthService.currentUserId()
		let payload = UpsertProfilePayload(
			id: userId.uuidString,
			name: name?.trimmingCharacters(in: .whitespacesAndNewlines),
			email: email?.trimmingCharacters(in: .whitespacesAndNewlines),
			phone: phone?.trimmingCharacters(in: .whitespacesAndNewlines),
			organization: organization?.trimmingCharacters(in: .whitespacesAndNewlines),
			locale: "es"
		)
		let updated: ProfileDTO = try await SupaClient.shared
			.from("profiles")
			.upsert(payload, onConflict: "id")
			.select()
			.single()
			.execute()
			.value
		return updated
	}
	
	func getCurrent() async throws -> ProfileDTO {
		let userId = try await SupaAuthService.currentUserId()
		let profile: ProfileDTO = try await SupaClient.shared
			.from("profiles")
			.select()
			.eq("id", value: userId.uuidString)
			.single()
			.execute()
			.value
		return profile
	}
	#else
	func upsertCurrentUserProfile(name: String?, email: String?, phone: String?, organization: String?) async throws -> ProfileDTO { throw NSError(domain: "supabase", code: -1) }
	func getCurrent() async throws -> ProfileDTO { throw NSError(domain: "supabase", code: -1) }
	#endif
}
