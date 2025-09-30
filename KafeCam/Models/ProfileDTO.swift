//
// ProfileDTO.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation

struct ProfileDTO: Codable, Identifiable, Hashable {
	let id: UUID
	let phone: String?
	let name: String?
	let email: String?
	let role: String?
	let organization: String?
	let locale: String?
	let createdAt: Date?
	
	enum CodingKeys: String, CodingKey {
		case id
		case phone
		case name
		case email
		case role
		case organization
		case locale
		case createdAt = "created_at"
	}
}
