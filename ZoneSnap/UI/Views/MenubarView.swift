//
//  MenubarView.swift
//  ZoneSnap
//
//  UI — contenido del menú de la barra de estado.
//

import SwiftUI

/// Contenido del `MenuBarExtra`: abrir el editor, arrancar al inicio y salir.
struct MenubarView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var launchAtLogin: LaunchAtLoginModel

    var body: some View {
        Button("Abrir editor", systemImage: "rectangle.split.2x2") {
            openWindow(id: ZoneSnapWindow.editor)
        }

        Divider()

        Toggle("Arrancar al iniciar sesión", isOn: launchAtLoginBinding)

        Divider()

        Button("Salir de ZoneSnap", systemImage: "power") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            set: { launchAtLogin.setEnabled($0) }
        )
    }
}

/// Identificadores de las ventanas de la app.
enum ZoneSnapWindow {
    static let editor = "editor"
}
