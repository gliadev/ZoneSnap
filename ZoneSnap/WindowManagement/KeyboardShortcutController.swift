//
//  KeyboardShortcutController.swift
//  ZoneSnap
//
//  WindowManagement — atajos globales que mueven la ventana activa entre zonas.
//

import AppKit
import CoreGraphics

/// Escucha los atajos de teclado (Control+Option + dígito/flecha) y mueve la
/// ventana de la app activa a la zona correspondiente del monitor seleccionado.
///
/// La lógica de qué zona se decide en `ShortcutResolver` + `ZoneNavigator`
/// (testeables); esto es glue de AppKit (monitores de eventos) + lectura de la
/// ventana actual vía `WindowMoving`. Verificación manual. Requiere permiso de
/// Accesibilidad (lo pide el `WindowSnapper` al mover).
@MainActor
final class KeyboardShortcutController {
    private let app: AppModel
    private let snapper: WindowSnapper
    private let mover: any WindowMoving

    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(app: AppModel, snapper: WindowSnapper, mover: any WindowMoving) {
        self.app = app
        self.snapper = snapper
        self.mover = mover
    }

    /// Instancia para previews de SwiftUI (no instala monitores hasta `start()`).
    static var preview: KeyboardShortcutController {
        KeyboardShortcutController(app: .preview, snapper: .preview, mover: AXWindowMover())
    }

    /// Instala los monitores de teclas (global = otras apps; local = ZoneSnap).
    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated { _ = self?.handle(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated { self?.handle(event) ?? false }
            return handled ? nil : event
        }
    }

    @discardableResult
    private func handle(_ event: NSEvent) -> Bool {
        guard let key = Self.shortcutKey(for: event) else { return false }
        let flags = event.modifierFlags
        guard let action = ShortcutResolver.action(
            key: key,
            control: flags.contains(.control),
            option: flags.contains(.option)
        ) else { return false }
        perform(action)
        return true
    }

    private func perform(_ action: ShortcutAction) {
        guard let monitor = app.selectedMonitor else { return }
        let zones = app.savedZones(for: monitor.id)
        guard !zones.isEmpty else { return }
        let current = currentZoneID(in: zones, on: monitor)
        guard let destination = ZoneNavigator.destination(for: action, in: zones, current: current) else { return }
        snapper.snap(localRect: destination.rect, on: monitor)
    }

    /// Zona donde está ahora la ventana activa (por el centro de su frame).
    private func currentZoneID(in zones: [Zone], on monitor: Monitor) -> Zone.ID? {
        guard
            let pid = snapper.lastActiveOtherPID,
            let frame = try? mover.focusedWindowFrame(ofPID: pid),
            let origin = WindowSnapper.globalTopLeftOrigin(of: monitor)
        else { return nil }

        let localCenter = CGPoint(x: frame.midX - origin.x, y: frame.midY - origin.y)
        let grid = ZoneGrid(zones: zones)
        return (grid.zone(at: localCenter) ?? grid.nearestZone(to: localCenter))?.id
    }

    /// Traduce el `NSEvent` a la tecla relevante (flechas o dígitos 1…9).
    private static func shortcutKey(for event: NSEvent) -> ShortcutKey? {
        switch event.keyCode {
        case 123: return .arrowLeft
        case 124: return .arrowRight
        default:
            if let characters = event.charactersIgnoringModifiers,
               let digit = Int(characters), (1...9).contains(digit) {
                return .digit(digit)
            }
            return nil
        }
    }
}
