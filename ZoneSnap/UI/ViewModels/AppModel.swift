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

    @ObservationIgnored private var autosaveTask: Task<Void, Never>?

    init(repository: any ZoneConfigRepository, monitorProvider: any MonitorProviding) {
        self.repository = repository
        self.monitorProvider = monitorProvider
    }

    var selectedMonitor: Monitor? {
        monitors.first { $0.id == selectedMonitorID }
    }

    func start() async {
        await refreshMonitors()
        try? await loadConfig()
    }

    func refreshMonitors() async {
        monitors = await monitorProvider.currentMonitors()
        if selectedMonitorID == nil || !monitors.contains(where: { $0.id == selectedMonitorID }) {
            selectedMonitorID = monitors.first?.id
        }
    }

    func loadConfig() async throws {
        config = try await repository.load()
    }

    /// Zonas guardadas para un monitor (vacío si no hay layout guardado).
    func savedZones(for monitorID: Monitor.ID) -> [Zone] {
        savedLayout(for: monitorID)?.grid.zones ?? []
    }

    /// Layout guardado para un monitor (incluye el árbol de subdivisión).
    func savedLayout(for monitorID: Monitor.ID) -> Layout? {
        config.monitors.first { $0.monitor.id == monitorID }?.layout
    }

    /// Árbol de subdivisión guardado para un monitor (modelo del editor BSP).
    func savedTree(for monitorID: Monitor.ID) -> ZoneNode? {
        savedLayout(for: monitorID)?.tree
    }

    /// Actualiza (upsert) el layout de un monitor **solo en memoria**.
    func setLayout(
        zones: [Zone],
        tree: ZoneNode? = nil,
        for monitor: Monitor,
        layoutName: String = "Personalizado"
    ) {
        let layout = Layout(name: layoutName, grid: ZoneGrid(zones: zones), tree: tree)
        let pairing = MonitorLayout(monitor: monitor, layout: layout)
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

    /// Guarda (upsert) el layout del monitor dado y persiste a disco.
    func save(
        zones: [Zone],
        tree: ZoneNode? = nil,
        for monitor: Monitor,
        layoutName: String = "Personalizado"
    ) async throws {
        setLayout(zones: zones, tree: tree, for: monitor, layoutName: layoutName)
        try await persist()
    }

    /// Programa un auto-guardado: actualiza en memoria al instante y persiste a
    /// disco tras una pausa, cancelando el guardado previo (debounce).
    func scheduleAutosave(
        zones: [Zone],
        tree: ZoneNode? = nil,
        for monitor: Monitor
    ) {
        setLayout(zones: zones, tree: tree, for: monitor)
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            try? await self?.persist()
        }
    }
}

// MARK: - Perfiles de distribución

extension AppModel {
    var profiles: [LayoutProfile] {
        config.profiles
    }

    func saveProfile(name: String, tree: ZoneNode) async throws {
        if let index = config.profiles.firstIndex(where: { $0.name == name }) {
            config.profiles[index].tree = tree
        } else {
            config.profiles.append(LayoutProfile(name: name, tree: tree))
        }
        try await persist()
    }

    func deleteProfile(_ id: LayoutProfile.ID) async throws {
        config.profiles.removeAll { $0.id == id }
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
