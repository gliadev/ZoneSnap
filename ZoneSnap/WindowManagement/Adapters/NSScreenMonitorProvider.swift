//
//  NSScreenMonitorProvider.swift
//  ZoneSnap
//
//  WindowManagement — adapter de monitores sobre NSScreen.
//

import AppKit
import CoreGraphics
import Foundation

/// Adapter: obtiene los monitores reales desde `NSScreen`.
///
/// La identidad estable de cada `Monitor` se deriva de
/// `CGDisplayCreateUUIDFromDisplayID`, que devuelve un UUID constante por
/// display físico entre reinicios. No es unit-testable (depende del hardware);
/// el mapeo puro vive en `MonitorMapper`. Verificación manual.
@MainActor
struct NSScreenMonitorProvider: MonitorProviding {
    func currentMonitors() async -> [Monitor] {
        var raws: [RawScreen] = []
        for screen in NSScreen.screens {
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            let uuid = displayID.flatMap(Self.stableUUID(for:)) ?? UUID()
            raws.append(RawScreen(displayUUID: uuid, name: screen.localizedName, size: screen.frame.size))
        }
        return MonitorMapper.monitors(from: raws)
    }

    /// UUID estable del display físico, o `nil` si el sistema no lo expone.
    /// `nonisolated`: es CoreGraphics puro, sin dependencia del main actor.
    nonisolated static func stableUUID(for displayID: CGDirectDisplayID) -> UUID? {
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }
        let string = CFUUIDCreateString(kCFAllocatorDefault, cfUUID) as String
        return UUID(uuidString: string)
    }
}
