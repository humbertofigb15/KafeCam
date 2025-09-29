//
// SupabaseConfig.swift
// KafeCam
//
// Created by Jose Manuel Sanchez on 28/09/25
//

import Foundation

enum SupabaseConfig {
	static let url = URL(string: "https://dmctlhsjdwykywrjmpax.supabase.co")!
	static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtY3RsaHNqZHd5a3l3cmptcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0NjU4MTUsImV4cCI6MjA3MzA0MTgxNX0.34WixD2nWiqQl4gD7Vc-jSoEzbQ_lTPmzVM6ezS5rbM"
	static let devEmail = "test@test.com"      // RLS testing only
	static let devPassword = "test123"       // RLS testing only
}
