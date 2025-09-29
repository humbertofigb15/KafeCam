//
// CapturesRepository.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct CapturesRepository {
	/// TODO: This will call our team API to generate a signed URL for Storage upload.
	/// For security, do not mint signed URLs in-app. This is a stub to compile.
	func createSignedUploadURL(filename: String) async throws -> (objectKey: String, url: URL) {
		throw NSError(domain: "todo", code: -1, userInfo: [NSLocalizedDescriptionKey: "TODO: Use team API to get signed upload URL"]) 
	}
	
	#if canImport(Supabase)
	private struct NewCapturePayload: Encodable {
		let plotId: String
		let uploadedByUserId: String
		let takenAt: String
		let photoKey: String
		let clientUUID: String?
		let createdOfflineAt: String?
		let deviceModel: String?
		let checksumSha256: String?
		
		enum CodingKeys: String, CodingKey {
			case plotId = "plot_id"
			case uploadedByUserId = "uploaded_by_user_id"
			case takenAt = "taken_at"
			case photoKey = "photo_key"
			case clientUUID = "client_uuid"
			case createdOfflineAt = "created_offline_at"
			case deviceModel = "device_model"
			case checksumSha256 = "checksum_sha256"
		}
	}
	
	func createCapture(plotId: UUID, takenAt: Date, photoKey: String, clientUUID: UUID? = nil, deviceModel: String? = nil, checksumSha256: String? = nil, createdOfflineAt: Date? = nil) async throws -> CaptureDTO {
		let userId = try await SupaAuthService.currentUserId()
		let iso = ISO8601DateFormatter()
		let payload = NewCapturePayload(
			plotId: plotId.uuidString,
			uploadedByUserId: userId.uuidString,
			takenAt: iso.string(from: takenAt),
			photoKey: photoKey,
			clientUUID: clientUUID?.uuidString,
			createdOfflineAt: createdOfflineAt.map { iso.string(from: $0) },
			deviceModel: deviceModel,
			checksumSha256: checksumSha256
		)
		let inserted: CaptureDTO = try await SupaClient.shared
			.from("captures")
			.insert(payload)
			.select()
			.single()
			.execute()
			.value
		return inserted
	}
	#else
	func createCapture(plotId: UUID, takenAt: Date, photoKey: String, clientUUID: UUID? = nil, deviceModel: String? = nil, checksumSha256: String? = nil, createdOfflineAt: Date? = nil) async throws -> CaptureDTO { throw NSError(domain: "supabase", code: -1) }
	#endif
}
