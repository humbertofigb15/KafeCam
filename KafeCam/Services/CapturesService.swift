//
// CapturesService.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct CapturesService {
	#if canImport(Supabase)
	let capturesRepo = CapturesRepository()
	
	/// Saves a capture referencing a photo key in Storage. Upload is TODO via team API.
	func saveCapture(plotId: UUID, imageData: Data, takenAt: Date = Date(), deviceModel: String? = nil) async throws -> CaptureDTO {
		let userId = try await SupaAuthService.currentUserId()
		let objectKey = "\(userId.uuidString)/\(UUID().uuidString).jpg"
		// TODO: call team API to get signed URL, then upload imageData
		let capture = try await capturesRepo.createCapture(
			plotId: plotId,
			takenAt: takenAt,
			photoKey: objectKey,
			clientUUID: UUID(),
			deviceModel: deviceModel,
			checksumSha256: nil,
			createdOfflineAt: nil
		)
		return capture
	}
	#else
	func saveCapture(plotId: UUID, imageData: Data, takenAt: Date = Date(), deviceModel: String? = nil) async throws -> CaptureDTO { throw NSError(domain: "supabase", code: -1) }
	#endif
}
