//
//  MapModel.swift
//  KafeCam
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Estatus SOLO para el Mapa (renombrado)
enum MapPlotStatus: String, CaseIterable, Identifiable {
    case sano = "Sano"
    case sospecha = "Sospecha"
    case enfermo = "Enfermo"
    var id: String { rawValue }
}

// MARK: - Pin
struct MapPlotPin: Identifiable, Equatable {
    let id: UUID
    var coordinate: CLLocationCoordinate2D
    var name: String
    var status: MapPlotStatus
    var plantedAt: Date?

    init(id: UUID = UUID(),
         coordinate: CLLocationCoordinate2D,
         name: String = "Plantío",
         status: MapPlotStatus = .sano,
         plantedAt: Date? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.status = status
        self.plantedAt = plantedAt
    }

    static func == (lhs: MapPlotPin, rhs: MapPlotPin) -> Bool { lhs.id == rhs.id }
}

// MARK: - Notifications
extension Notification.Name {
    static let kafeCreatePin = Notification.Name("kafeCreatePin")
    static let kafePinAdded = Notification.Name("kafePinAdded")
    static let kafePinAddFailedNoLocation = Notification.Name("kafePinAddFailedNoLocation")
}

// MARK: - ViewModel
@MainActor
final class PlotsMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // Base (Chiapas)
    let baseCoordinate = CLLocationCoordinate2D(latitude: 15.7846022, longitude: -92.7611756)

    // Región y estado
    @Published var region: MKCoordinateRegion
    @Published var pins: [MapPlotPin] = []
    @Published var selectedPin: MapPlotPin?
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var isAddingPin = false

    private var manager: CLLocationManager?
    private var pinCreateObserver: NSObjectProtocol?

    override init() {
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 15.7846022, longitude: -92.7611756),
            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        )
        super.init()
        startLocation()
        pins.append(MapPlotPin(coordinate: baseCoordinate, name: "Base"))

        // Escuchar creación automática de pines (Detecta)
        pinCreateObserver = NotificationCenter.default.addObserver(
            forName: .kafeCreatePin,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let userInfo = note.userInfo ?? [:]

            // Preferimos estado directo (string: "sano" | "sospecha" | "enfermo")
            if let estadoStr = userInfo["estado"] as? String {
                let status = Self.status(from: estadoStr)
                self.handleAutoPin(status: status)
                return
            }

            // Respaldo por porcentaje (si alguna vez llega)
            if let prob = userInfo["probabilidad"] as? Double {
                self.handleAutoPin(probabilidad: prob)
            }
        }
    }

    deinit {
        if let obs = pinCreateObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Location
    private func startLocation() {
        let m = CLLocationManager()
        m.delegate = self
        m.desiredAccuracy = kCLLocationAccuracyBest

        switch m.authorizationStatus {
        case .notDetermined:
            m.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            m.startUpdatingLocation()
            m.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
        self.manager = m
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(manager.authorizationStatus, manager: manager)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorization(status, manager: manager)
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus, manager: CLLocationManager) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userCoordinate = locations.last?.coordinate
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    // MARK: - Acciones manuales
    func addPin(at coordinate: CLLocationCoordinate2D) {
        let newPin = MapPlotPin(coordinate: coordinate, name: "Plantío \(pins.count + 1)")
        pins.append(newPin)
        selectedPin = newPin
        isAddingPin = false
    }
    func updatePin(_ pin: MapPlotPin) {
        if let idx = pins.firstIndex(where: { $0.id == pin.id }) { pins[idx] = pin }
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

    // MARK: - Auto pin desde Detecta
    private func handleAutoPin(status: MapPlotStatus) {
        guard let coord = userCoordinate else {
            NotificationCenter.default.post(name: .kafePinAddFailedNoLocation, object: nil)
            return
        }
        let newPin = MapPlotPin(
            coordinate: coord,
            name: "Plantío \(pins.count + 1)",
            status: status,
            plantedAt: Date()
        )
        pins.append(newPin)

        // (Opcional) enfocar al nuevo pin
        // region = MKCoordinateRegion(center: coord, span: .init(latitudeDelta: 0.03, longitudeDelta: 0.03))

        NotificationCenter.default.post(name: .kafePinAdded, object: nil)
    }

    private func handleAutoPin(probabilidad: Double) {
        let status: MapPlotStatus
        switch probabilidad {
        case 70...100: status = .enfermo
        case 40..<70:  status = .sospecha
        default:       status = .sano
        }
        handleAutoPin(status: status)
    }

    // String → MapPlotStatus
    private static func status(from raw: String) -> MapPlotStatus {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "enfermo", "enfermedad", "sick", "diseased": return .enfermo
        case "sospecha", "suspected", "sospechoso":       return .sospecha
        case "sano", "sana", "healthy":                   return .sano
        default:                                          return .sospecha
        }
    }
}
