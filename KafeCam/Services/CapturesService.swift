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
    let plotsRepo = PlotsRepository()
	
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

    /// Convenience: ensures the user has at least one plot and returns its id.
    func ensureDefaultPlotId() async throws -> UUID {
        let existing = try await plotsRepo.listPlots()
        if let first = existing.first { return first.id }
        let created = try await plotsRepo.createPlot(name: "Mi lote", lat: nil, lon: nil, region: nil)
        return created.id
    }

    /// Saves a capture using (or creating) a default plot for the current user.
    func saveCaptureToDefaultPlot(imageData: Data, takenAt: Date = Date(), deviceModel: String? = nil) async throws -> CaptureDTO {
        let plotId = try await ensureDefaultPlotId()
        return try await saveCapture(plotId: plotId, imageData: imageData, takenAt: takenAt, deviceModel: deviceModel)
    }
	#else
	func saveCapture(plotId: UUID, imageData: Data, takenAt: Date = Date(), deviceModel: String? = nil) async throws -> CaptureDTO { throw NSError(domain: "supabase", code: -1) }
	#endif
}
