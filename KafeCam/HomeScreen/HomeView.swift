//
//  HomeView.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 08/09/25.
//
import SwiftUI

struct HomeView: View {
    @AppStorage("displayName") private var displayName: String = "Grecia"
    @StateObject private var vm = HomeViewModel()
    @State private var query: String = ""

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return listaEnfermedades.filter { $0.localizedCaseInsensitiveContains(q) }
                                .prefix(10).map { String($0) }
    }

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // HEADER: Saludo + Avatar
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hola, \(displayName.isEmpty ? vm.greetingName : displayName) 👋")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(vm.accentColor)
                                    .lineLimit(1)

                                Text("Todo lo que tu cafetal necesita...")
                                    .italic()
                                    .foregroundColor(vm.darkColor)
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

                        // Search bar
                        SearchBar(text: $query)

                        // Coincidencias
                        if !filtered.isEmpty {
                            Text("Coincidencias")
                                .font(.headline)

                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(filtered, id: \.self) { item in
                                    Button { query = item } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "leaf.fill")
                                                .foregroundStyle(.secondary)
                                            Text(item)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
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
                        } else if !query.isEmpty {
                            Text("Sin resultados para “\(query)”")
                                .foregroundStyle(.secondary)
                        }

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

                        // Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                  spacing: 10) {
                            ActionCardView(color: green1, systemImage: "cloud.sun.fill",
                                           title: "Anticipa", subtitle: "Prevé el clima")
                            ActionCardView(color: brown1, systemImage: "camera.fill",
                                           title: "Detecta", subtitle: "Prevención temprana")
                            NavigationLink {
                                DiseaseView()
                            } label: {
                                ActionCardView(color: brown2, systemImage: "bandage.fill",
                                               title: "Infórmate", subtitle: "Cuida tu cultivo")
                            }
                            NavigationLink {
                                HistoryView()
                            } label: {
                                ActionCardView(color: green2, systemImage: "leaf.fill", title: "Consulta", subtitle: "Tus registros siempre")}
                        }
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
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

#Preview {
    HomeView()
}
