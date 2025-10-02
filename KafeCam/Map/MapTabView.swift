//
//  MapTabView.swift
//  KafeCam
//

import SwiftUI
import MapKit

struct MapTabView: View {
    @StateObject private var vm = PlotsMapViewModel()
    @State private var showHint = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // Mapa con punto azul y pines
                    Map(
                        coordinateRegion: $vm.region,
                        interactionModes: .all,
                        showsUserLocation: true,
                        userTrackingMode: .constant(.none),
                        annotationItems: vm.pins
                    ) { pin in
                        MapAnnotation(coordinate: pin.coordinate) {
                            Button { vm.selectedPin = pin } label: {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(color(for: pin.status))
                                    .padding(6)
                                    .background(.white, in: Circle())
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .ignoresSafeArea()

                    // Overlay SOLO cuando vamos a colocar un pin
                    Color.clear
                        .contentShape(Rectangle())
                        .allowsHitTesting(vm.isAddingPin)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    guard vm.isAddingPin else { return }
                                    let pt = value.location
                                    let coord = toCoordinate(point: pt, in: geo.size, region: vm.region)
                                    vm.addPin(at: coord)
                                    withAnimation { showHint = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                        withAnimation { showHint = false }
                                    }
                                }
                        )

                    // Menú vertical flotante (derecha)
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button { vm.isAddingPin = true } label: {
                                menuButton(icon: "mappin.and.ellipse", color: .blue)
                            }
                            Button { vm.resetToBase() } label: {
                                menuButton(icon: "house.fill", color: .orange)
                            }
                            Button { vm.goToUser() } label: {
                                menuButton(icon: "location.fill", color: .red)
                            }
                            ForEach(Array(vm.pins.enumerated()), id: \.1.id) { idx, pin in
                                Button { vm.goToPin(pin) } label: {
                                    menuButton(icon: "\(idx + 1).circle.fill", color: .green)
                                }
                            }
                        }
                        .padding(.trailing, 12)
                        .padding(.bottom, 28)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    if showHint {
                        VStack {
                            Spacer()
                            Text("📍 Pin agregado")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 3)
                                .padding(.bottom, 70)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if vm.isAddingPin {
                        VStack {
                            Text("Toca el mapa para colocar el pin")
                                .font(.callout.weight(.semibold))
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.top, 12)
                            Spacer()
                        }
                        .transition(.opacity)
                    }
                }
            }
            .navigationTitle("Mapa")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $vm.selectedPin) { pin in
                PinDetailSheet(
                    pin: binding(for: pin),
                    onSave: { vm.updatePin($0) },
                    onDelete: { vm.removePin($0) }
                )
            }
        }
    }

    // Binding real al pin dentro del array del VM
    private func binding(for pin: MapPlotPin) -> Binding<MapPlotPin> {
        guard let idx = vm.pins.firstIndex(where: { $0.id == pin.id }) else {
            fatalError("Pin no encontrado")
        }
        return $vm.pins[idx]
    }

    // MARK: - Helpers UI / Coord

    private func menuButton(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(.white)
            .padding()
            .background(color, in: Circle())
            .shadow(radius: 3)
    }

    private func color(for status: PlotStatus) -> Color {
        switch status {
        case .sano:     return .green
        case .sospecha: return .yellow
        case .enfermo:  return .red
        }
    }

    /// Conversión aproximada punto (en la vista) → coordenada usando la región visible
    private func toCoordinate(point: CGPoint, in size: CGSize, region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        let dx = (point.x - size.width  / 2.0) / size.width
        let dy = (size.height / 2.0 - point.y) / size.height
        let lat = region.center.latitude  + Double(dy) * latDelta
        let lon = region.center.longitude + Double(dx) * lonDelta
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Sheet de detalle
struct PinDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var pin: MapPlotPin
    var onSave: (MapPlotPin) -> Void
    var onDelete: (MapPlotPin) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Nombre del plantío", text: $pin.name)

                    Picker("Estatus", selection: $pin.status) {
                        ForEach(PlotStatus.allCases) { st in
                            Text(st.rawValue).tag(st)
                        }
                    }

                    // ✅ FIX: DatePicker necesita Binding<Date>
                    DatePicker(
                        "Fecha de plantación",
                        selection: $pin.plantedAt.unwrap(Date()),
                        displayedComponents: .date
                    )
                }

                Section {
                    Button(role: .destructive) {
                        onDelete(pin)
                        dismiss()
                    } label: {
                        Label("Eliminar pin", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Plantío")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(pin)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper genérico: Binding<Optional> → Binding<Wrapped>
extension Binding {
    /// Convierte un `Binding<T?>` en `Binding<T>` proporcionando un valor por defecto.
    func unwrap<T>(_ defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
