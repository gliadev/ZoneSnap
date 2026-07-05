//
//  KeyboardShortcutController.swift
//  ZoneSnap
//
//  WindowManagement — atajos globales que mueven la ventana activa entre zonas.
//

import AppKit
import Carbon.HIToolbox
import CoreGraphics

/// Escucha los atajos de teclado (Control+Option + dígito/flecha) y mueve la
/// ventana de la app activa a la zona correspondiente del monitor seleccionado.
///
/// Usa **`RegisterEventHotKey`** (Carbon) en lugar de un `NSEvent` global: registra
/// hotkeys de sistema *reales* que se entregan a la app aunque esté en background,
/// consumen la combinación (no se la queda la app de delante) y **no dependen del
/// permiso de Accesibilidad para recibir la tecla** — ese permiso solo hace falta
/// luego, al mover la ventana ajena (lo pide el `WindowSnapper`).
///
/// La lógica de qué zona se decide en `ShortcutResolver` + `ZoneNavigator`
/// (testeables); esto es glue de Carbon/AppKit + lectura de la ventana actual vía
/// `WindowMoving`. Verificación manual.
@MainActor
final class KeyboardShortcutController {
    private let app: AppModel
    private let snapper: WindowSnapper
    private let mover: any WindowMoving

    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []

    /// Firma común de los hotkeys de ZoneSnap ('ZNSP').
    private static let signature: OSType = 0x5A4E_5350

    /// Tabla (keyCode físico, id de hotkey). Los dígitos 1…9 usan id = dígito; las
    /// flechas usan ids altos para no chocar. El id se traduce de vuelta a
    /// `ShortcutKey` en `shortcutKey(forHotKeyID:)`.
    private static let hotKeyTable: [(keyCode: UInt32, id: UInt32)] = [
        (UInt32(kVK_ANSI_1), 1),
        (UInt32(kVK_ANSI_2), 2),
        (UInt32(kVK_ANSI_3), 3),
        (UInt32(kVK_ANSI_4), 4),
        (UInt32(kVK_ANSI_5), 5),
        (UInt32(kVK_ANSI_6), 6),
        (UInt32(kVK_ANSI_7), 7),
        (UInt32(kVK_ANSI_8), 8),
        (UInt32(kVK_ANSI_9), 9),
        (UInt32(kVK_LeftArrow), 1001),
        (UInt32(kVK_RightArrow), 1002)
    ]

    init(app: AppModel, snapper: WindowSnapper, mover: any WindowMoving) {
        self.app = app
        self.snapper = snapper
        self.mover = mover
    }

    /// Instancia para previews de SwiftUI (no registra hotkeys hasta `start()`).
    static var preview: KeyboardShortcutController {
        KeyboardShortcutController(app: .preview, snapper: .preview, mover: AXWindowMover())
    }

    /// Instala el handler de Carbon y registra los hotkeys globales. Idempotente.
    func start() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), zoneSnapHotKeyHandler, 1, &eventType, selfPtr, &eventHandler)

        let modifiers = UInt32(controlKey | optionKey)
        for entry in Self.hotKeyTable {
            var ref: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: entry.id)
            let status = RegisterEventHotKey(entry.keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref { hotKeyRefs.append(ref) }
        }
    }

    /// Da de baja los hotkeys y el handler (cleanup; la app los mantiene vivos
    /// todo su ciclo, así que en la práctica rara vez se llama).
    func stop() {
        for ref in hotKeyRefs { UnregisterEventHotKey(ref) }
        hotKeyRefs.removeAll()
        if let eventHandler { RemoveEventHandler(eventHandler) }
        eventHandler = nil
    }

    /// Punto de entrada desde el callback de Carbon (ya en el hilo principal).
    func handleHotKey(id: UInt32) {
        guard let key = Self.shortcutKey(forHotKeyID: id) else { return }
        // Los hotkeys se registran con Control+Option fijos; reusamos la lógica de
        // dominio para mantener una única fuente de verdad de las acciones.
        guard let action = ShortcutResolver.action(key: key, control: true, option: true) else { return }
        perform(action)
    }

    private func perform(_ action: ShortcutAction) {
        let windowFrame = snapper.lastActiveOtherPID.flatMap { try? mover.focusedWindowFrame(ofPID: $0) }
        guard let monitor = targetMonitor(windowFrame: windowFrame) else { return }
        let zones = app.savedZones(for: monitor.id)
        guard !zones.isEmpty else { return }
        let current = currentZoneID(windowFrame: windowFrame, in: zones, on: monitor)
        guard let destination = ZoneNavigator.destination(for: action, in: zones, current: current) else { return }
        snapper.snap(localRect: destination.rect, on: monitor)
    }

    /// Monitor donde está la ventana activa (por su centro); si no se puede
    /// determinar, el seleccionado en el editor.
    private func targetMonitor(windowFrame: CGRect?) -> Monitor? {
        guard let frame = windowFrame else { return app.selectedMonitor }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let rects = app.monitors.compactMap { monitor -> (id: Monitor.ID, frame: CGRect)? in
            guard let origin = WindowSnapper.globalTopLeftOrigin(of: monitor) else { return nil }
            return (monitor.id, CGRect(origin: origin, size: monitor.resolution))
        }
        if let id = MonitorLocator.monitor(containing: center, in: rects) {
            return app.monitors.first { $0.id == id }
        }
        return app.selectedMonitor
    }

    /// Zona donde está ahora la ventana activa (por el centro de su frame) en el
    /// monitor dado.
    private func currentZoneID(windowFrame: CGRect?, in zones: [Zone], on monitor: Monitor) -> Zone.ID? {
        guard
            let frame = windowFrame,
            let origin = WindowSnapper.globalTopLeftOrigin(of: monitor)
        else { return nil }

        let localCenter = CGPoint(x: frame.midX - origin.x, y: frame.midY - origin.y)
        let grid = ZoneGrid(zones: zones)
        return (grid.zone(at: localCenter) ?? grid.nearestZone(to: localCenter))?.id
    }

    /// Traduce el id del hotkey de vuelta a la tecla de dominio.
    private static func shortcutKey(forHotKeyID id: UInt32) -> ShortcutKey? {
        switch id {
        case 1...9: return .digit(Int(id))
        case 1001: return .arrowLeft
        case 1002: return .arrowRight
        default: return nil
        }
    }
}

/// Callback de Carbon (C). Corre en el hilo principal (los handlers de eventos de
/// la aplicación se despachan en el run loop principal), por eso `assumeIsolated`.
/// Recupera el controller desde `userData` y delega.
private func zoneSnapHotKeyHandler(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }

    let id = hotKeyID.id
    return MainActor.assumeIsolated {
        let controller = Unmanaged<KeyboardShortcutController>.fromOpaque(userData).takeUnretainedValue()
        controller.handleHotKey(id: id)
        return noErr
    }
}
