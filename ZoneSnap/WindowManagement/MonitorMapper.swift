//
//  MonitorMapper.swift
//  ZoneSnap
//
//  WindowManagement — mapeo puro de pantallas crudas a Monitor del Domain.
//

import CoreGraphics
import Foundation

/// Datos crudos de una pantalla, desacoplados de `NSScreen` para poder testear
/// el mapeo a `Monitor` sin hardware.
struct RawScreen: Sendable, Equatable {
    /// UUID estable del display físico (de `CGDisplayCreateUUIDFromDisplayID`).
    let displayUUID: UUID
    let name: String?
    let size: CGSize
}

/// Convierte pantallas crudas en `Monitor` del Domain. La identidad estable la
/// aporta `RawScreen.displayUUID`, constante por display físico entre reinicios.
enum MonitorMapper {
    static func monitors(from screens: [RawScreen]) -> [Monitor] {
        screens.map { screen in
            Monitor(id: screen.displayUUID, name: screen.name, resolution: screen.size)
        }
    }
}
