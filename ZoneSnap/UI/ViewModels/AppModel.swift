//
//  AppModel.swift
//  ZoneSnap
//
//  UI — estado de aplicación: monitores, selección y persistencia.
//

import CoreGraphics
import Foundation
import Observation

/// Estado compartido de la app: lista de monitores, monitor seleccionado y la
/// configuración persistida. Coordina los puertos de detección de monitores y
/// de persistencia, manteniéndose testeable mediante inyección.
@MainActor
@Observable
final class AppModel {
    private let repository: any ZoneConfigRepository
    private let monitorProvider: any MonitorProviding

    private(set) var monitors: [Monitor] = []
    var selectedMonitorID: Monitor.ID?
    private(set) var config = ZoneConfig()

    init(repository: any ZoneConfigRepository, monitorProvider: any MonitorProviding) {
        self.repository = repository
        self.monitorProvider = monitorProvider
    }

    /// Monitor actualmente seleccionado, si lo hay.
    var selectedMonitor: Monitor? {
        monitors.first { $0.id == selectedMonitorID }
    }

    /// Carga monitores y configuración al arrancar la UI.
    func start() async {
        await refreshMonitors()
        try? await loadConfig()
    }

    /// Recarga los monitores conectados; mantiene o ajusta la selección.
    func refreshMonitors() async {
        monitors = await monitorProvider.currentMonitors()
        if selectedMonitorID == nil || !monitors.contains(where: { $0.id == selectedMonitorID }) {
            selectedMonitorID = monitors.first?.id
        }
    }

    /// Carga la configuración persistida.
    func loadConfig() async throws {
        config = try await repository.load()
    }

    /// Zonas guardadas para un monitor (vacío si no hay layout guardado).
    func savedZones(for monitorID: Monitor.ID) -> [Zone] {
        config.monitors.first { $0.monitor.id == monitorID }?.layout.grid.zones ?? []
    }

    /// Actualiza (upsert) el layout de un monitor **solo en memoria**. Se usa al
    /// cambiar de monitor para no perder la edición en curso.
    func setLayout(zones: [Zone], for monitor: Monitor, layoutName: String = "Personalizado") {
        let pairing = MonitorLayout(
            monitor: monitor,
            layout: Layout(name: layoutName, grid: ZoneGrid(zones: zones))
        )
        if let index = config.monitors.firstIndex(where: { $0.monitor.id == monitor.id }) {
            config.monitors[index] = pairing
        } else {
            config.monitors.append(pairing)
        }
    }

    /// Persiste la configuración actual a disco.
    func persist() async throws {
        try await repository.save(config)
    }

    /// Guarda (upsert) las zonas del monitor dado y persiste a disco.
    func save(zones: [Zone], for monitor: Monitor, layoutName: String = "Personalizado") async throws {
        setLayout(zones: zones, for: monitor, layoutName: layoutName)
        try await persist()
    }
}

extension AppModel {
    /// Instancia para previews de SwiftUI: en memoria, con monitores de ejemplo.
    static var preview: AppModel {
        AppModel(
            repository: InMemoryZoneConfigRepository(),
            monitorProvider: StaticMonitorProvider(monitors: [
                Monitor(name: "Built-in", resolution: CGSize(width: 1920, height: 1080)),
                Monitor(name: "LG UltraWide", resolution: CGSize(width: 3440, height: 1440))
            ])
        )
    }
}
