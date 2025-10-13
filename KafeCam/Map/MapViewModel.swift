//
//  MapModel.swift
//  KafeCam
//
//  Created by Guillermo Lira on 01/10/25.
//


import Foundation
import MapKit
import CoreLocation

// Estatus del plantío
enum PlotStatus: String, CaseIterable, Identifiable {
    case sano = "Sano"
    case sospecha = "Sospecha"
    case enfermo = "Enfermo"
    var id: String { rawValue }
}

// Pin con metadatos
struct MapPlotPin: Identifiable, Equatable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var name: String
    var status: PlotStatus
    var plantedAt: Date?

    init(id: UUID = UUID(),
         coordinate: CLLocationCoordinate2D,
         name: String = "Plantío",
         status: PlotStatus = .sano,
         plantedAt: Date? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.status = status
        self.plantedAt = plantedAt
    }

    static func == (lhs: MapPlotPin, rhs: MapPlotPin) -> Bool { lhs.id == rhs.id }
}

@MainActor
final class PlotsMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // Coordenada base (Chiapas)
    let baseCoordinate = CLLocationCoordinate2D(latitude: 15.7846022, longitude: -92.7611756)

    // Región visible
    @Published var region: MKCoordinateRegion

    // Pines y selección para sheet
    @Published var pins: [MapPlotPin] = []
    @Published var selectedPin: MapPlotPin?

    // Ubicación del usuario
    @Published var userCoordinate: CLLocationCoordinate2D?

    // Modo: esperando toque para colocar pin
    @Published var isAddingPin = false

    private var manager: CLLocationManager?

    override init() {
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 15.7846022, longitude: -92.7611756),
            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        )
        super.init()
        startLocation()
        // Pin inicial opcional (Base)
        pins.append(MapPlotPin(coordinate: baseCoordinate, name: "Base"))
    }

    // MARK: - Location
    private func startLocation() {
        let m = CLLocationManager()
        m.delegate = self
        m.desiredAccuracy = kCLLocationAccuracyBest
        // Si ya está determinado, no pedimos otra vez
        switch m.authorizationStatus {
        case .notDetermined: m.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: m.startUpdatingLocation()
        case .denied, .restricted: break
        @unknown default: break
        }
        self.manager = m
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        userCoordinate = latest.coordinate
        // No recentramos aquí para no romper el pan/zoom del usuario
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    // MARK: - Acciones de mapa / pines
    func addPin(at coordinate: CLLocationCoordinate2D) {
        let newPin = MapPlotPin(coordinate: coordinate, name: "Plantío \(pins.count + 1)")
        pins.append(newPin)
        selectedPin = newPin
        isAddingPin = false
    }

    func updatePin(_ pin: MapPlotPin) {
        if let idx = pins.firstIndex(where: { $0.id == pin.id }) {
            pins[idx] = pin
        }
    }

    func removePin(_ pin: MapPlotPin) {
        pins.removeAll { $0.id == pin.id }
        if selectedPin?.id == pin.id { selectedPin = nil }
    }

    func resetToBase() {
        region = MKCoordinateRegion(center: baseCoordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35))
    }

    func goToUser() {
        guard let u = userCoordinate else { return }
        region = MKCoordinateRegion(center: u,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }

    func goToPin(_ pin: MapPlotPin) {
        region = MKCoordinateRegion(center: pin.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        selectedPin = pin
    }
}
