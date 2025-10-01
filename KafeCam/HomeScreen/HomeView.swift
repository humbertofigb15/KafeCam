//
//  HomeView.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 08/09/25.
//
import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("profileInitials") private var profileInitials: String = ""
    @StateObject private var vm = HomeViewModel()
    @State private var query: String = ""

    // filtro simple
    private var filtered: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let hits = listaEnfermedades.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        return Array(hits.prefix(10)).map { String($0) }
    }

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        Header(displayName: displayName,
                               greetingName: vm.greetingName,
                               accent: vm.accentColor,
                               dark: vm.darkColor,
                               initials: profileInitials)

                        // buscador
                        SearchBar(text: $query)

                        // coincidencias
                        MatchesList(filtered: filtered, onTap: { query = $0 })

                        // alertas
                        if !vm.alerts.isEmpty {
                            Text("Alertas")
                                .font(.headline)
                                .foregroundColor(vm.accentColor)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.alerts) { alert in
                                        AlertCard(alert: alert)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }

                        Text("¿Qué quieres hacer hoy?")
                            .foregroundColor(vm.accentColor)
                            .fontWeight(.semibold)

                        // grid de acciones
                        ActionsGrid()
                    }
                    .padding(.horizontal)
                }
                // teclado
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle("")
                .toolbar(.hidden, for: .navigationBar)
                .onAppear { vm.refresh() }
                .task { await syncProfileToAppStorage() }
            }
            .tabItem { Label("Inicio", systemImage: "house.fill") }

            ProfileTabView()
                .tabItem { Label("Perfil", systemImage: "person.fill") }

            Text("Favoritos")
                .tabItem { Label("Favoritos", systemImage: "heart.fill") }
        }
        .tint(vm.accentColor)
    }

    // sincroniza nombre e iniciales
    private func syncProfileToAppStorage() async {
        do {
            let p = try await ProfilesRepository().getCurrent()
            let first = (p.name ?? "").split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? (p.name ?? "")
            UserDefaults.standard.set(first, forKey: "displayName")
            let initials = Self.makeInitials(from: p.name)
            UserDefaults.standard.set(initials, forKey: "profileInitials")
        } catch {
            // no-op
        }
    }

    private static func makeInitials(from name: String?) -> String {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return "" }
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}

// MARK: - Subvistas

private struct Header: View {
    let displayName: String
    let greetingName: String
    let accent: Color
    let dark: Color
    let initials: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hola, \((displayName.isEmpty ? greetingName : displayName)) 👋")
                    .font(.largeTitle.bold())
                    .foregroundColor(accent)
                    .lineLimit(1)

                Text("Todo lo que tu cafetal necesita...")
                    .italic()
                    .foregroundColor(dark)
                    .fontWeight(.medium)
            }
            Spacer(minLength: 0)
            AvatarCircle(initials: initials)
        }
        .padding(.top, 8)
    }
}

private struct AvatarCircle: View {
    let initials: String
    var body: some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            Text(initials.isEmpty ? "" : initials)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(width: 40, height: 40)
        .overlay(Circle().stroke(.white, lineWidth: 1))
        .shadow(radius: 3)
    }
}

private struct MatchesList: View {
    let filtered: [String]
    let onTap: (String) -> Void

    var body: some View {
        Group {
            if !filtered.isEmpty {
                Text("Coincidencias").font(.headline)
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(filtered, id: \.self) { item in
                        Button { onTap(item) } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill").foregroundStyle(.secondary)
                                Text(item).foregroundStyle(.primary).lineLimit(1)
                                Spacer()
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: filtered)
            }
        }
    }
}

private struct ActionsGrid: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {

            // ANTICIPA
            NavigationLink {
                AnticipaView()
            } label: {
                ActionCardView(color: green1, systemImage: "cloud.sun.fill",
                               title: "Anticipa", subtitle: "Prevé el clima")
                    .contentShape(Rectangle())
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            })

            // DETECTA
            NavigationLink {
                DetectaView()
            } label: {
                ActionCardView(color: brown1,
                               systemImage: "camera.fill",
                               title: "Detecta",
                               subtitle: "Prevención temprana")
                    .contentShape(Rectangle())
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            })

            // INFÓRMATE
            NavigationLink {
                DiseaseView(diseaseList: sampleDiseases)
            } label: {
                ActionCardView(color: brown2, systemImage: "bandage.fill",
                               title: "Infórmate", subtitle: "Cuida tu cultivo")
                    .contentShape(Rectangle())
            }

            // CONSULTA
            NavigationLink {
                HistoryView()
            } label: {
                ActionCardView(color: green2, systemImage: "leaf.fill",
                               title: "Consulta", subtitle: "Tus registros siempre")
                    .contentShape(Rectangle())
            }
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            })
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
