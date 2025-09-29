//
// SupaClient.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

enum SupaClient {
	#if canImport(Supabase)
	static let shared: SupabaseClient = {
		let client = SupabaseClient(
			supabaseURL: SupabaseConfig.url,
			supabaseKey: SupabaseConfig.anonKey
		)
		return client
	}()
	#endif
}

enum SupaAuthService {
	#if canImport(Supabase)
	static func signInDev() async throws {
		_ = try await SupaClient.shared.auth.signIn(
			email: SupabaseConfig.devEmail,
			password: SupabaseConfig.devPassword
		)
	}
	
	/// Map a 10-digit user code to an email used by Supabase email auth.
	static func email(for code: String) -> String {
		"\(code)@kafe.local"
	}
	
	/// Sign in the user derived from the 10-digit code, or create the account if missing.
	@discardableResult
	static func signInOrSignUp(code: String, password: String) async throws -> UUID {
		let emailAddr = email(for: code)
		do {
			let session = try await SupaClient.shared.auth.signIn(email: emailAddr, password: password)
			return session.user.id
		} catch {
			// Try sign up then sign in. If email confirmation is enabled, this may require dashboard changes.
			_ = try await SupaClient.shared.auth.signUp(email: emailAddr, password: password)
			let session = try await SupaClient.shared.auth.signIn(email: emailAddr, password: password)
			return session.user.id
		}
	}
	
	/// Current signed-in user id. Assumes you've called a sign-in method before use.
	static func currentUserId() async throws -> UUID {
		try await SupaClient.shared.auth.session.user.id
	}
	#else
	static func signInDev() async throws { }
	static func email(for code: String) -> String { code }
	@discardableResult
	static func signInOrSignUp(code: String, password: String) async throws -> UUID { UUID() }
	static func currentUserId() async throws -> UUID { UUID() }
	#endif
}
