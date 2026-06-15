//
//  WindowSnapper.swift
//  ZoneSnap
//
//  WindowManagement — orquesta el movimiento de la ventana activa a una zona.
//

import AppKit
import CoreGraphics
import Observation

/// Coordina el "snap" de la ventana de la última app activa (distinta de
/// ZoneSnap) a un rectángulo de zona. Reúne permiso, app objetivo, origen del
/// monitor y el `WindowMoving`. Es glue de sistema (NSWorkspace/NSScreen);
/// verificación manual.
@MainActor
@Observable
final class WindowSnapper {
    private let mover: any WindowMoving
    private let authorizer: any AccessibilityAuthorizing

    /// PID de la última app activa distinta de ZoneSnap (la que se moverá).
    private(set) var lastActiveOtherPID: pid_t?

    /// Mensaje de estado del último intento, para mostrar en la UI.
    private(set) var statusMessage: String?

    init(mover: any WindowMoving, authorizer: any AccessibilityAuthorizing) {
        self.mover = mover
        self.authorizer = authorizer
    }

    /// Observa los cambios de app activa para recordar la última que no es
    /// ZoneSnap (a la que se aplicará el movimiento).
    func startObservingActiveApp() {
        let center = NSWorkspace.shared.notificationCenter
        Task { [weak self] in
            for await note in center.notifications(named: NSWorkspace.didActivateApplicationNotification) {
                guard
                    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                    app.bundleIdentifier != Bundle.main.bundleIdentifier
                else { continue }
                self?.lastActiveOtherPID = app.processIdentifier
            }
        }
    }

    /// Mueve la ventana de la última app activa al rect local dado del monitor.
    /// Pide el permiso de Accesibilidad si falta.
    func snap(localRect: CGRect, on monitor: Monitor) {
        guard authorizer.isTrusted else {
            authorizer.requestAccess()
            statusMessage = "Concede el permiso de Accesibilidad y vuelve a intentarlo."
            return
        }
        guard let pid = lastActiveOtherPID else {
            statusMessage = "Cambia a la ventana que quieras mover y vuelve a intentarlo."
            return
        }
        guard let origin = Self.globalTopLeftOrigin(of: monitor) else {
            statusMessage = "No encuentro ese monitor en pantalla."
            return
        }

        let frame = WindowFrameCalculator.globalFrame(localRect: localRect, monitorOrigin: origin)
        do {
            try mover.moveFocusedWindow(ofPID: pid, to: frame)
            statusMessage = "Ventana movida ✓"
        } catch {
            statusMessage = "No se pudo mover la ventana: \(error)"
        }
    }

    /// Origen top-left global del monitor, buscando su `NSScreen` por display UUID
    /// y convirtiendo desde coordenadas AppKit (bottom-left).
    static func globalTopLeftOrigin(of monitor: Monitor) -> CGPoint? {
        let screens = NSScreen.screens
        guard let primary = screens.first(where: { $0.frame.origin == .zero }) ?? screens.first else {
            return nil
        }
        let converter = CoordinateConverter(primaryHeight: primary.frame.height)
        for screen in screens {
            guard
                let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                let uuid = NSScreenMonitorProvider.stableUUID(for: displayID),
                uuid == monitor.id
            else { continue }
            return converter.toTopLeft(screen.frame).origin
        }
        return nil
    }
}
