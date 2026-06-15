//
//  EditorView.swift
//  ZoneSnap
//
//  UI — pantalla principal del editor de zonas.
//

import SwiftUI

/// Editor visual de zonas: elige monitor, configura la rejilla y guarda el
/// layout. El estado de app (monitores + persistencia) llega en `app`; el
/// estado de edición vive en un `EditorViewModel` propio.
struct EditorView: View {
    let app: AppModel
    @State private var editor = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080))

    var body: some View {
        @Bindable var app = app

        VStack(spacing: 20) {
            HStack {
                Picker("Monitor", selection: $app.selectedMonitorID) {
                    ForEach(app.monitors) { monitor in
                        Text(monitor.name ?? "Monitor").tag(Optional(monitor.id))
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()

                Spacer()

                Button("Guardar", systemImage: "square.and.arrow.down", action: saveLayout)
                    .disabled(app.selectedMonitor == nil)
            }

            MonitorPreview(bounds: editor.bounds, zones: editor.previewZones, lines: editor.lines)
                .frame(maxWidth: .infinity)

            EditorControls(model: editor)

            Text("\(editor.previewZones.count) zonas")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 520, minHeight: 460)
        .navigationTitle("Editor de zonas")
        .task {
            await app.start()
            configureEditor(for: app.selectedMonitorID)
        }
        .onChange(of: app.selectedMonitorID) { _, newID in
            configureEditor(for: newID)
        }
    }

    /// Ajusta el editor al monitor seleccionado y carga sus zonas guardadas.
    private func configureEditor(for monitorID: Monitor.ID?) {
        guard let monitor = app.monitors.first(where: { $0.id == monitorID }) else { return }
        editor.updateBounds(CGRect(origin: .zero, size: monitor.resolution))
        editor.load(app.savedZones(for: monitor.id))
    }

    private func saveLayout() {
        guard let monitor = app.selectedMonitor else { return }
        Task { try? await app.save(zones: editor.previewZones, for: monitor) }
    }
}

#Preview {
    EditorView(app: .preview)
}
