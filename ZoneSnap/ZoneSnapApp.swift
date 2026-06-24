//
//  ZoneSnapApp.swift
//  ZoneSnap
//
//  Punto de entrada de la app: ventana del editor + menú de barra de estado.
//

import AppKit
import SwiftUI

/// Delegate de la app: crea los servicios y los arranca al lanzar (no al abrir el
/// editor), de modo que los atajos y el drag funcionen aunque el editor esté
/// cerrado. Además fija la app como accesoria (sin icono en el Dock).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let app: AppModel
    let snapper: WindowSnapper
    let dragOverlay: DragOverlayController
    let shortcuts: KeyboardShortcutController
    let launchAtLogin: LaunchAtLoginModel

    override init() {
        let appModel = AppModel(
            repository: LocalZoneConfigRepository(),
            monitorProvider: NSScreenMonitorProvider()
        )
        let mover = AXWindowMover()
        let windowSnapper = WindowSnapper(mover: mover, authorizer: SystemAccessibilityAuthorizer())
        app = appModel
        snapper = windowSnapper
        dragOverlay = DragOverlayController(app: appModel, mover: mover)
        shortcuts = KeyboardShortcutController(app: appModel, snapper: windowSnapper, mover: mover)
        launchAtLogin = LaunchAtLoginModel(manager: SystemLoginItemManager())
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        snapper.startObservingActiveApp()
        dragOverlay.start()
        shortcuts.start()
        Task { await app.start() }
    }
}

@main
struct ZoneSnapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("ZoneSnap — Editor", id: ZoneSnapWindow.editor) {
            EditorView(
                app: appDelegate.app,
                snapper: appDelegate.snapper,
                dragOverlay: appDelegate.dragOverlay,
                shortcuts: appDelegate.shortcuts
            )
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra("ZoneSnap", systemImage: "rectangle.split.2x2") {
            MenubarView(launchAtLogin: appDelegate.launchAtLogin)
        }
    }
}
