//
//  EditorView.swift
//  ZoneSnap
//
//  UI — pantalla principal del editor de zonas.
//

import SwiftUI

/// Editor visual de zonas: elige monitor, configura la rejilla (arrastrando las
/// líneas para redimensionar), aplica/guarda perfiles, selecciona zonas y mueve
/// la ventana activa sobre ellas.
struct EditorView: View {
    let app: AppModel
    let snapper: WindowSnapper
    @State private var editor = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080))

    @State private var profileName = ""
    @State private var showingNamePrompt = false

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

                profileMenu(app: app)

                Spacer()

                Button("Guardar", systemImage: "square.and.arrow.down", action: saveLayout)
                    .disabled(app.selectedMonitor == nil)
            }

            MonitorPreview(
                bounds: editor.bounds,
                zones: editor.previewZones,
                lines: editor.lines,
                selectedZoneIDs: editor.selectedZoneIDs,
                onSelectZone: { id, extending in editor.selectZone(id, extending: extending) },
                onMoveLine: { id, position in editor.moveLine(id, to: position) }
            )
            .frame(maxWidth: .infinity)

            EditorControls(model: editor)

            Text("Arrastra las líneas blancas para redimensionar · click para seleccionar (Shift = varias)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Mover ventana activa aquí", systemImage: "macwindow.on.rectangle", action: moveWindow)
                    .disabled(editor.selectionRect == nil || app.selectedMonitor == nil)

                Spacer()

                Text("\(editor.previewZones.count) zonas · \(editor.selectedZones.count) seleccionadas")
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
        .frame(minWidth: 580, minHeight: 540)
        .navigationTitle("Editor de zonas")
        .task {
            await app.start()
            snapper.startObservingActiveApp()
            configureEditor(for: app.selectedMonitorID)
        }
        .onChange(of: app.selectedMonitorID) { oldID, newID in
            if let oldMonitor = app.monitors.first(where: { $0.id == oldID }) {
                app.setLayout(zones: editor.previewZones, for: oldMonitor)
            }
            configureEditor(for: newID)
        }
        .alert("Guardar perfil", isPresented: $showingNamePrompt) {
            TextField("Nombre (p. ej. dev)", text: $profileName)
            Button("Guardar", action: saveProfile)
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Guarda la distribución actual como perfil reutilizable en cualquier monitor.")
        }
    }

    private func profileMenu(app: AppModel) -> some View {
        Menu("Perfil", systemImage: "rectangle.3.group") {
            if app.profiles.isEmpty {
                Text("Sin perfiles guardados")
            } else {
                ForEach(app.profiles) { profile in
                    Button(profile.name) { applyProfile(profile) }
                }
                Divider()
                Menu("Borrar perfil") {
                    ForEach(app.profiles) { profile in
                        Button(profile.name, role: .destructive) { deleteProfile(profile) }
                    }
                }
            }
            Divider()
            Button("Guardar como perfil…", systemImage: "plus") {
                profileName = ""
                showingNamePrompt = true
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
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

    private func moveWindow() {
        guard let rect = editor.selectionRect, let monitor = app.selectedMonitor else { return }
        snapper.snap(localRect: rect, on: monitor)
    }

    private func applyProfile(_ profile: LayoutProfile) {
        editor.applyLines(LayoutProfileMapper.denormalize(profile.lines, in: editor.bounds))
    }

    private func saveProfile() {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        Task { try? await app.saveProfile(name: name, lines: editor.lines, bounds: editor.bounds) }
    }

    private func deleteProfile(_ profile: LayoutProfile) {
        Task { try? await app.deleteProfile(profile.id) }
    }
}

#Preview {
    EditorView(app: .preview, snapper: .preview)
}
