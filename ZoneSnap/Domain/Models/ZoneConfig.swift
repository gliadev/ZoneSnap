//
//  ZoneConfig.swift
//  ZoneSnap
//
//  Domain — documento raíz persistible de la configuración.
//

import Foundation

/// Documento raíz persistible: la configuración completa de ZoneSnap.
///
/// Se serializa a `zones.json`. `version` permite migraciones futuras del
/// formato en disco.
struct ZoneConfig: Codable, Sendable, Hashable {
    /// Versión del formato en disco. Incrementar ante cambios incompatibles.
    var version: Int

    /// Layout asignado a cada monitor conocido.
    var monitors: [MonitorLayout]

    init(version: Int = ZoneConfig.currentVersion, monitors: [MonitorLayout] = []) {
        self.version = version
        self.monitors = monitors
    }
}

extension ZoneConfig {
    /// Versión actual del formato de `zones.json`.
    static let currentVersion = 1
}

/// Asociación entre un monitor y el layout activo en él.
///
/// Se evita un diccionario `[Monitor.ID: Layout]` porque las claves `UUID` no
/// serializan a JSON como objeto (Swift las codifica como array). Un array de
/// asociaciones coincide además con el formato descrito en `SPEC.md`.
struct MonitorLayout: Identifiable, Codable, Sendable, Hashable {
    /// La identidad de la asociación es la del propio monitor.
    var id: Monitor.ID { monitor.id }

    var monitor: Monitor
    var layout: Layout

    init(monitor: Monitor, layout: Layout) {
        self.monitor = monitor
        self.layout = layout
    }
}
