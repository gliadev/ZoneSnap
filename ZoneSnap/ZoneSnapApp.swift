//
//  ZoneSnapApp.swift
//  ZoneSnap
//
//  Punto de entrada de la app: ventana del editor + menú de barra de estado.
//

import SwiftUI

@main
struct ZoneSnapApp: App {
    var body: some Scene {
        Window("ZoneSnap — Editor", id: ZoneSnapWindow.editor) {
            EditorView()
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra("ZoneSnap", systemImage: "rectangle.split.2x2") {
            MenubarView()
        }
    }
}
