//
//  EditorView.swift
//  ZoneSnap
//
//  UI — pantalla principal del editor de zonas.
//

import SwiftUI

/// Editor visual de zonas: elige monitor, selecciona una zona y la subdivide en
/// columnas/filas (local, sin romper el resto), arrastra los separadores para
/// redimensionar, une divisiones y mueve la ventana activa. El layout por
/// monitor se auto-guarda.
struct EditorView: View {
    let app: AppModel
    let snapper: WindowSnapper
    let dragOverlay: DragOverlayController
    @State private var editor = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080))

    var body: some View {
        @Bindable var app = app

        VStack(spacing: 16) {
            HStack {
                Picker("Monitor", selection: $app.selectedMonitorID) {
                    ForEach(app.monitors) { monitor in
                        Text(monitor.name ?? "Monitor").tag(Optional(monitor.id))
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()

                Spacer()
            }

            MonitorPreview(
                bounds: editor.bounds,
                zones: editor.previewZones,
                boundaries: editor.boundaries,
                selectedZoneID: editor.selectedZoneID,
                onSelectZone: { id in editor.selectZone(id) },
                onMoveBoundary: { boundary, position in editor.moveBoundary(boundary, to: position) }
            )
            .frame(maxWidth: .infinity)

            EditorControls(model: editor)

            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Mover ventana activa aquí", systemImage: "macwindow.on.rectangle", action: moveWindow)
                    .disabled(editor.selectionRect == nil || app.selectedMonitor == nil)

                Spacer()

                Text("\(editor.previewZones.count) zonas\(editor.hasSelection ? " · 1 seleccionada" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let message = snapper.statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 540)
        .navigationTitle("Editor de zonas")
        .task {
            await app.start()
            snapper.startObservingActiveApp()
            dragOverlay.start()
            configureEditor(for: app.selectedMonitorID)
        }
        .onChange(of: app.selectedMonitorID) { oldID, newID in
            if let oldMonitor = app.monitors.first(where: { $0.id == oldID }) {
                app.setLayout(zones: editor.previewZones, tree: editor.tree, for: oldMonitor)
            }
            configureEditor(for: newID)
        }
        .onChange(of: editor.previewZones) { _, _ in
            if let monitor = app.selectedMonitor {
                app.scheduleAutosave(zones: editor.previewZones, tree: editor.tree, for: monitor)
            }
        }
    }

    private var hint: String {
        editor.hasSelection
            ? "Columnas/Filas subdividen la zona seleccionada · arrastra los separadores para redimensionar · Unir colapsa la división · ⇧⌃ + arrastrar ventana para acoplar"
            : "Selecciona una zona para subdividirla en columnas/filas · ⇧⌃ + arrastrar ventana para acoplar"
    }

    /// Ajusta el editor al monitor seleccionado y restaura su árbol guardado
    /// (o lo reconstruye de zonas si es una configuración antigua).
    private func configureEditor(for monitorID: Monitor.ID?) {
        guard let monitor = app.monitors.first(where: { $0.id == monitorID }) else { return }
        editor.updateBounds(CGRect(origin: .zero, size: monitor.resolution))
        if let tree = app.savedTree(for: monitor.id) {
            editor.applyTree(tree)
        } else {
            editor.load(app.savedZones(for: monitor.id))
        }
    }

    private func moveWindow() {
        guard let rect = editor.selectionRect, let monitor = app.selectedMonitor else { return }
        snapper.snap(localRect: rect, on: monitor)
    }
}

#Preview {
    EditorView(app: .preview, snapper: .preview, dragOverlay: .preview)
}
