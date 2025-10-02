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
		print("[SupabaseAuth] Starting registration for phone: \(phone)")
		_ = try Self.blocking {
			let userId = try await SupaAuthService.signUpThenSignIn(code: phone, password: password, metaName: name, metaOrg: organization, metaPhone: phone, metaEmail: (email?.isEmpty == true ? nil : email))
			print("[SupabaseAuth] User created with ID: \(userId)")
			
			// Ensure profile is properly synced
			do {
				let profiles = ProfilesRepository()
				let profile = try await profiles.upsertCurrentUserProfile(
					name: name,
					email: (email?.isEmpty == true ? nil : email),
					phone: phone,
					organization: organization
				)
				print("[SupabaseAuth] Profile synced - Name: \(profile.name ?? "nil"), Phone: \(profile.phone ?? "nil")")
				
				// Update display name
				if let full = profile.name?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
					let first = full.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? full
					UserDefaults.standard.set(first, forKey: "displayName")
					print("[SupabaseAuth] Display name set to: \(first)")
				}
			} catch {
				print("[SupabaseAuth] Profile sync after signup failed: \(error)")
			}
		}
		currentPhone = phone
	}
	
	func login(phone: String, password: String) throws {
		guard Self.validateCode(phone) else { throw AuthError.userNotFoundOrBadPassword }
		print("[SupabaseAuth] Starting login for phone: \(phone)")
		_ = try Self.blocking {
			let userId = try await SupaAuthService.signInOrSignUp(code: phone, password: password)
			print("[SupabaseAuth] Logged in with User ID: \(userId)")
			
			// Ensure profile exists and sync display name
			do {
				let profiles = ProfilesRepository()
				let me = try await profiles.getOrCreateCurrent()
				print("[SupabaseAuth] Profile fetched - Name: \(me.name ?? "nil"), Phone: \(me.phone ?? "nil")")
				
				if let full = me.name?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
					let first = full.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? full
					UserDefaults.standard.set(first, forKey: "displayName")
					print("[SupabaseAuth] Display name refreshed to: \(first)")
				}
			} catch {
				print("[SupabaseAuth] Profile sync after login failed: \(error)")
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
