//
//  DragOverlayController.swift
//  ZoneSnap
//
//  WindowManagement — overlay de zonas durante el arrastre de ventanas (F4).
//

import AppKit
import CoreGraphics
import SwiftUI

/// Muestra el overlay de zonas mientras se arrastra una ventana manteniendo
/// **⇧⌃ (Shift+Control)**, y al soltar acopla la ventana a la zona resaltada.
///
/// Glue de sistema (monitores globales de `NSEvent` + `NSWindow` overlay +
/// `AXUIElement`); no es unit-testable. El cálculo de zona/frame se delega en
/// piezas puras testeadas (`OverlayModel`, `WindowFrameCalculator`).
@MainActor
final class DragOverlayController {
    private let app: AppModel
    private let mover: any WindowMoving
    private let overlayModel = OverlayModel()

    private var overlayWindow: NSWindow?
    private var monitors: [Any] = []
    private var draggedPID: pid_t?
    private var activeScreen: NSScreen?
    private var isStarted = false

    init(app: AppModel, mover: any WindowMoving) {
        self.app = app
        self.mover = mover
    }

    /// Instala los monitores globales de ratón (idempotente).
    func start() {
        guard !isStarted else { return }
        isStarted = true

        let dragged = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleDrag() }
        }
        let up = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleDrop() }
        }
        monitors = [dragged, up].compactMap { $0 }
    }

    private var triggerActive: Bool {
        NSEvent.modifierFlags.contains([.shift, .control])
    }

    private func handleDrag() {
        guard triggerActive else { hideOverlay(); return }

        let mouse = NSEvent.mouseLocation
        guard
            let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }),
            let monitorID = Self.monitorID(for: screen)
        else { hideOverlay(); return }

        let zones = app.savedZones(for: monitorID)
        guard !zones.isEmpty else { hideOverlay(); return }

        if draggedPID == nil {
            draggedPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        }

        showOverlay(on: screen, zones: zones)
        overlayModel.highlightZone(at: Self.localPoint(of: mouse, in: screen))
    }

    private func handleDrop() {
        defer {
            draggedPID = nil
            hideOverlay()
        }
        guard
            let pid = draggedPID,
            let screen = activeScreen,
            let zoneID = overlayModel.highlightedZoneID,
            let zone = overlayModel.zones.first(where: { $0.id == zoneID })
        else { return }

        let origin = Self.globalTopLeftOrigin(of: screen)
        let frame = WindowFrameCalculator.globalFrame(localRect: zone.rect, monitorOrigin: origin)
        try? mover.moveFocusedWindow(ofPID: pid, to: frame)
    }

    // MARK: - Ventana overlay

    private func showOverlay(on screen: NSScreen, zones: [Zone]) {
        overlayModel.configure(bounds: CGRect(origin: .zero, size: screen.frame.size), zones: zones)
        activeScreen = screen

        let window = overlayWindow ?? makeOverlayWindow()
        overlayWindow = window
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
    }

    private func makeOverlayWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: ZoneOverlayView(model: overlayModel))
        return window
    }

    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
        activeScreen = nil
        overlayModel.highlightedZoneID = nil
    }

    // MARK: - Geometría

    private static func monitorID(for screen: NSScreen) -> Monitor.ID? {
        guard
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        else { return nil }
        return NSScreenMonitorProvider.stableUUID(for: displayID)
    }

    /// Ratón global (AppKit bottom-left) → punto local del monitor (top-left).
    private static func localPoint(of mouse: CGPoint, in screen: NSScreen) -> CGPoint {
        CGPoint(x: mouse.x - screen.frame.minX, y: screen.frame.maxY - mouse.y)
    }

    /// Origen top-left global del monitor (para componer el frame de destino).
    private static func globalTopLeftOrigin(of screen: NSScreen) -> CGPoint {
        let primaryHeight = (NSScreen.screens.first { $0.frame.origin == .zero } ?? screen).frame.height
        return CoordinateConverter(primaryHeight: primaryHeight).toTopLeft(screen.frame).origin
    }
}
