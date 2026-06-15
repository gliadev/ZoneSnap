//
//  EditorView.swift
//  ZoneSnap
//
//  UI — pantalla principal del editor de zonas.
//

import SwiftUI

/// Editor visual de zonas: muestra la preview del monitor y los controles para
/// configurar la rejilla. Posee el `EditorViewModel`.
struct EditorView: View {
    @State private var model: EditorViewModel

    init(bounds: CGRect = CGRect(x: 0, y: 0, width: 1920, height: 1080)) {
        _model = State(initialValue: EditorViewModel(bounds: bounds))
    }

    var body: some View {
        VStack(spacing: 20) {
            MonitorPreview(bounds: model.bounds, zones: model.previewZones, lines: model.lines)
                .frame(maxWidth: .infinity)

            EditorControls(model: model)

            Text("\(model.previewZones.count) zonas")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 520, minHeight: 420)
        .navigationTitle("Editor de zonas")
    }
}

#Preview {
    EditorView()
}
