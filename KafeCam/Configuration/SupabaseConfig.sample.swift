//
// SupabaseConfig.sample.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation

enum SupabaseConfig {
	static let url = URL(string: "https://YOUR-PROJECT.supabase.co")!
	static let anonKey = "YOUR-ANON-KEY"
	static let devEmail = "dev@example.com"      // RLS testing only
	static let devPassword = "changeme123"       // RLS testing only
}
