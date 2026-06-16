//
//  ZoneSnapApp.swift
//  ZoneSnap
//
//  Punto de entrada de la app: ventana del editor + menú de barra de estado.
//

import AppKit
import SwiftUI

/// Delegate mínimo para convertir ZoneSnap en una app de barra de estado pura
/// (sin icono en el Dock). El editor se abre desde el menú de la barra.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct ZoneSnapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var app: AppModel
    @State private var snapper: WindowSnapper
    @State private var dragOverlay: DragOverlayController
    @State private var shortcuts: KeyboardShortcutController

    init() {
        let appModel = AppModel(
            repository: LocalZoneConfigRepository(),
            monitorProvider: NSScreenMonitorProvider()
        )
        let mover = AXWindowMover()
        let windowSnapper = WindowSnapper(mover: mover, authorizer: SystemAccessibilityAuthorizer())
        _app = State(initialValue: appModel)
        _snapper = State(initialValue: windowSnapper)
        _dragOverlay = State(initialValue: DragOverlayController(app: appModel, mover: mover))
        _shortcuts = State(initialValue: KeyboardShortcutController(app: appModel, snapper: windowSnapper, mover: mover))
    }

    var body: some Scene {
        Window("ZoneSnap — Editor", id: ZoneSnapWindow.editor) {
            EditorView(app: app, snapper: snapper, dragOverlay: dragOverlay, shortcuts: shortcuts)
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra("ZoneSnap", systemImage: "rectangle.split.2x2") {
            MenubarView()
        }
    }
}
