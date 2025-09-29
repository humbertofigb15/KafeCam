//
// SupabaseCodeAuthService.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation

final class SupabaseCodeAuthService: AuthService {
	private(set) var currentPhone: String? = nil
	
	func isLoggedIn() -> Bool {
		currentPhone != nil
	}
	
	func register(name: String, email: String?, phone: String, password: String, organization: String) throws {
		// Treat `phone` as a 10-digit code. Minimal validation: exactly 10 digits.
		guard Self.validateCode(phone) else { throw AuthError.invalidPhone }
		_ = try Self.blocking {
			try await SupaAuthService.signInOrSignUp(code: phone, password: password)
		}
		currentPhone = phone
	}
	
	func login(phone: String, password: String) throws {
		guard Self.validateCode(phone) else { throw AuthError.userNotFoundOrBadPassword }
		_ = try Self.blocking {
			try await SupaAuthService.signInOrSignUp(code: phone, password: password)
		}
		currentPhone = phone
	}
	
	func logout() {
		_ = try? Self.blocking {
			try await SupaClient.shared.auth.signOut()
		}
		currentPhone = nil
	}
	
	// MARK: - Helpers
	private static func blocking<T>(_ work: @escaping () async throws -> T) throws -> T {
		let semaphore = DispatchSemaphore(value: 0)
		var result: Result<T, Error>!
		Task {
			do { result = .success(try await work()) }
			catch { result = .failure(error) }
			semaphore.signal()
		}
		semaphore.wait()
		return try result.get()
	}
	
	private static func validateCode(_ code: String) -> Bool {
		let digits = CharacterSet.decimalDigits
		return code.count == 10 && code.unicodeScalars.allSatisfy { digits.contains($0) }
	}
}
