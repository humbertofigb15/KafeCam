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

    /// Fetch any profile by id (used by technician flows)
    func get(byId id: UUID) async throws -> ProfileDTO {
        let profile: ProfileDTO = try await SupaClient.shared
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        return profile
    }

    /// Ensure a profile row exists for the current user; create a populated row if missing, then return it.
    func getOrCreateCurrent() async throws -> ProfileDTO {
        do {
            // Try to fetch existing profile
            let profile = try await getCurrent()
            
            // If profile exists but critical fields are empty, populate them
            if (profile.phone == nil || profile.phone?.isEmpty == true || profile.name == nil || profile.name?.isEmpty == true) {
                // Get session metadata
                let session = try await SupaClient.shared.auth.session
                let loginCode = try? await SupaAuthService.currentLoginCode()
                let userMetadata = session.user.userMetadata
                
                // Extract metadata values
                let metaName = userMetadata["name"]?.stringValue
                let metaEmail = userMetadata["email"]?.stringValue  
                let metaPhone = userMetadata["phone"]?.stringValue ?? loginCode
                let metaOrg = userMetadata["organization"]?.stringValue
                
                // Update profile with any missing critical fields
                let updatedProfile = try await upsertCurrentUserProfile(
                    name: profile.name ?? metaName,
                    email: profile.email ?? metaEmail ?? session.user.email,
                    phone: profile.phone ?? metaPhone,
                    organization: profile.organization ?? metaOrg
                )
                return updatedProfile
            }
            
            return profile
        } catch {
            // Profile doesn't exist, create one with session metadata
            let userId = try await SupaAuthService.currentUserId()
            let session = try await SupaClient.shared.auth.session
            let loginCode = try? await SupaAuthService.currentLoginCode()
            let userMetadata = session.user.userMetadata
            
            // Extract metadata from session
            let metaName = userMetadata["name"]?.stringValue
            let metaEmail = userMetadata["email"]?.stringValue
            let metaPhone = userMetadata["phone"]?.stringValue ?? loginCode
            let metaOrg = userMetadata["organization"]?.stringValue
            
            // Create profile with all available metadata
            let payload = UpsertProfilePayload(
                id: userId.uuidString,
                name: metaName,
                email: metaEmail ?? session.user.email,
                phone: metaPhone,
                organization: metaOrg,
                locale: "es"
            )
            
            _ = try await SupaClient.shared
                .from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
                .value as Void
                
            return try await getCurrent()
        }
    }
	#else
	func upsertCurrentUserProfile(name: String?, email: String?, phone: String?, organization: String?) async throws -> ProfileDTO { throw NSError(domain: "supabase", code: -1) }
	func getCurrent() async throws -> ProfileDTO { throw NSError(domain: "supabase", code: -1) }
	func get(byId id: UUID) async throws -> ProfileDTO { throw NSError(domain: "supabase", code: -1) }
	#endif
}
