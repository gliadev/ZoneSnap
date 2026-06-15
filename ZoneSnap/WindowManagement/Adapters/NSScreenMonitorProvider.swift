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
        MonitorMapper.monitors(from: NSScreen.screens.map(Self.rawScreen(from:)))
    }

    private static func rawScreen(from screen: NSScreen) -> RawScreen {
        let uuid = screen.displayID.flatMap(stableUUID(for:)) ?? UUID()
        return RawScreen(displayUUID: uuid, name: screen.localizedName, size: screen.frame.size)
    }

    /// UUID estable del display físico, o `nil` si el sistema no lo expone.
    private static func stableUUID(for displayID: CGDirectDisplayID) -> UUID? {
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }
        let string = CFUUIDCreateString(kCFAllocatorDefault, cfUUID) as String
        return UUID(uuidString: string)
    }
}

private extension NSScreen {
    /// `CGDirectDisplayID` de la pantalla, extraído de `deviceDescription`.
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
