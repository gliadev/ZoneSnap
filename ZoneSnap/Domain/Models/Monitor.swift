//
//  Monitor.swift
//  ZoneSnap
//
//  Domain — descriptor puro de un monitor físico.
//

import CoreGraphics
import Foundation

/// Descriptor puro de un monitor físico.
///
/// La identidad (`id`) la genera y persiste ZoneSnap. El mapeo a un display
/// real de hardware (`CGDirectDisplayID` / `NSScreen`) se resolverá en la capa
/// WindowManagement (F2); el Domain permanece libre de AppKit.
struct Monitor: Identifiable, Codable, Sendable, Hashable {
    let id: UUID

    /// Nombre legible del monitor (p. ej. "Built-in", "LG UltraWide").
    var name: String?

    /// Resolución en puntos del área visible del monitor.
    var resolution: CGSize

    init(id: UUID = UUID(), name: String? = nil, resolution: CGSize) {
        self.id = id
        self.name = name
        self.resolution = resolution
    }
}
