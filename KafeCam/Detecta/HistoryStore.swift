//
//  HistoryStore.swift
//  KafeCam
//
//  Created by Humberto Figueroa on 01/10/25.
//

import SwiftUI
import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct HistoryEntry: Identifiable {
    let id = UUID()
    let image: UIImage
    let prediction: String
    let date: Date

    init(image: UIImage, prediction: String) {
        self.image = image
        self.prediction = prediction
        self.date = Date()
    }

    init(image: UIImage, prediction: String, date: Date) {
        self.image = image
        self.prediction = prediction
        self.date = date
    }
}

@MainActor
class HistoryStore: ObservableObject {
    @Published var entries: [HistoryEntry] = []
    @Published var sections: [TechnicianSection] = []
    
    func add(image: UIImage, prediction: String) {
        let entry = HistoryEntry(image: image, prediction: prediction)
        entries.append(entry)
    }

    struct TechnicianSection: Identifiable {
        let id: UUID
        let farmerName: String
        let farmerPhone: String?
        let entries: [HistoryEntry]
    }

    /// Fetch captures for current user, or for assigned farmers if the
    /// current user is a technician/admin. Maps into placeholder entries.
    func syncFromSupabase() async {
        #if canImport(Supabase)
        do {
            let placeholder = UIImage(systemName: "photo") ?? UIImage()
            let me = try await ProfilesRepository().getOrCreateCurrent()
            let role = me.role ?? "farmer"

            if role == "technician" || role == "admin" {
                // Load assigned farmers
                let assignRepo = TechnicianAssignmentsRepository()
                let farmers = try await assignRepo.listFarmersForCurrentTechnician()
                var out: [TechnicianSection] = []
                for f in farmers {
                    let caps = try await CapturesRepository().listCaptures(uploadedBy: f.id)
                    let mapped: [HistoryEntry] = caps.map { c in
                        HistoryEntry(image: placeholder, prediction: c.deviceModel ?? "Foto", date: c.takenAt)
                    }
                    let name = f.name ?? "(sin nombre)"
                    out.append(TechnicianSection(id: f.id, farmerName: name, farmerPhone: f.phone, entries: mapped))
                }
                self.sections = out
                self.entries = []
            } else {
                // Farmer: load own captures
                let userId = try await SupaAuthService.currentUserId()
                let items: [CaptureDTO] = try await SupaClient.shared
                    .from("captures")
                    .select()
                    .eq("uploaded_by_user_id", value: userId.uuidString)
                    .order("taken_at", ascending: false)
                    .execute()
                    .value
                let mapped: [HistoryEntry] = items.map { c in
                    HistoryEntry(image: placeholder, prediction: c.deviceModel ?? "Foto", date: c.takenAt)
                }
                self.sections = []
                self.entries = mapped
            }
        } catch {
            // no-op fallback to current entries
        }
        #endif
    }
}

