//
//  HomeView.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 08/09/25.
//
import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("displayName") private var displayName: String = "Grecia"
    @StateObject private var vm = HomeViewModel()
    @State private var query: String = ""

    // Rompemos la cadena para ayudar al type-checker
    private var filtered: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let base = listaEnfermedades
        let hits = base.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        let firstTen = Array(hits.prefix(10))
        return firstTen.map { String($0) }
    }

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        Header(displayName: displayName,
                               greetingName: vm.greetingName,
                               accent: vm.accentColor,
                               dark: vm.darkColor)

                        // Search bar
                        SearchBar(text: $query)

                        // Coincidencias
                        MatchesList(filtered: filtered, onTap: { query = $0 })

                        // Alertas
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

                        // Grid de acciones
                        ActionsGrid()
                    }
                    .padding(.horizontal)
                }
                // FIX teclado/conflictos de constraints
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle("")
                .toolbar(.hidden, for: .navigationBar)
                .onAppear { vm.refresh() }
            }
            .tabItem { Label("Inicio", systemImage: "house.fill") }

            Text("Perfil del usuario")
                .tabItem { Label("Perfil", systemImage: "person.fill") }

            Text("Favoritos")
                .tabItem { Label("Favoritos", systemImage: "heart.fill") }
        }
        .tint(vm.accentColor)
    }
}

// MARK: - Subvistas pequeñas (ayudan al type-checker)

private struct Header: View {
    let displayName: String
    let greetingName: String
    let accent: Color
    let dark: Color

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
            Image("Profile")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 1))
                .shadow(radius: 3)
        }
        .padding(.top, 8)
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
            ActionCardView(color: green1, systemImage: "cloud.sun.fill",
                           title: "Anticipa", subtitle: "Prevé el clima")

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
                // esto asegura que el teclado se cierre si estaba abierto
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            })
            
            NavigationLink {
                DiseaseView(diseaseList: sampleDiseases)
            } label: {
                ActionCardView(color: brown2, systemImage: "bandage.fill",
                                     title: "Infórmate", subtitle: "Cuida tu cultivo")
            }

            // CONSULTA (usa el NavigationStack ya existente)
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
