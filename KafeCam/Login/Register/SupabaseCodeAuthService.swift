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
		guard Self.validateCode(phone) else { throw AuthError.invalidPhone }
		_ = try Self.blocking {
			let _ = try await SupaAuthService.signUpThenSignIn(code: phone, password: password, metaName: name, metaOrg: organization, metaPhone: phone, metaEmail: (email?.isEmpty == true ? nil : email))
			// Best-effort profile sync; do not block signup on secondary failures
			do {
				let profiles = ProfilesRepository()
				let _ = try await profiles.upsertCurrentUserProfile(
					name: name,
					email: (email?.isEmpty == true ? nil : email),
					phone: phone,
					organization: organization
				)
				let me = try await profiles.getCurrent()
				if let full = me.name?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
					let first = full.split(whereSeparator: { $0.isWhitespace }).first.map(String.init)
					if let first, !first.isEmpty { UserDefaults.standard.set(first, forKey: "displayName") }
				}
			} catch {
				// Log but don't fail registration
				print("Profile sync after signup failed: \(error)")
			}
		}
		currentPhone = phone
	}
	
	func login(phone: String, password: String) throws {
		guard Self.validateCode(phone) else { throw AuthError.userNotFoundOrBadPassword }
		_ = try Self.blocking {
			let _ = try await SupaAuthService.signInOrSignUp(code: phone, password: password)
			// Best-effort display name refresh
			if let me = try? await ProfilesRepository().getCurrent(), let full = me.name?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
				let first = full.split(whereSeparator: { $0.isWhitespace }).first.map(String.init)
				if let first, !first.isEmpty { UserDefaults.standard.set(first, forKey: "displayName") }
			}
		}
		currentPhone = phone
	}
	
	func logout() {
		_ = try? Self.blocking { try await SupaAuthService.signOut() }
		currentPhone = nil
	}
	
	// MARK: - Helpers
	private static func blocking<T>(_ work: @escaping () async throws -> T) throws -> T {
		var output: Result<T, Error>? = nil
		let semaphore = DispatchSemaphore(value: 0)
		Task {
			do { output = .success(try await work()) }
			catch { output = .failure(error) }
			semaphore.signal()
		}
		while output == nil {
			RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
		}
		semaphore.wait()
		return try output!.get()
	}
	
	private static func validateCode(_ code: String) -> Bool {
		let digits = CharacterSet.decimalDigits
		return code.count == 10 && code.unicodeScalars.allSatisfy { digits.contains($0) }
	}
}
