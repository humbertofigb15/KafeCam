//
// FarmersListViewModel.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation
import SwiftUI

@MainActor
final class FarmersListViewModel: ObservableObject {
	@Published var farmers: [TechnicianAssignmentsRepository.FarmerSummary] = []
	@Published var isLoading = false
	@Published var errorMessage: String? = nil
	
	private let repo = TechnicianAssignmentsRepository()
	
	func load() {
		Task {
			isLoading = true
			defer { isLoading = false }
			do {
				farmers = try await repo.listFarmersForCurrentTechnician()
			} catch {
				errorMessage = (error as NSError).localizedDescription
			}
		}
	}
}
