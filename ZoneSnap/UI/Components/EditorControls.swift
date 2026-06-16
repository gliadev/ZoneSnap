//
//  EditorControls.swift
//  ZoneSnap
//
//  UI — controles del editor (columnas, filas, fusionar/separar, limpiar).
//

import SwiftUI

/// Controles para configurar la rejilla del editor. Opera sobre el
/// `EditorViewModel`, que es la fuente de verdad.
///
/// Los steppers de Columnas/Filas definen la **rejilla base** (resetean líneas y
/// fusiones), así que se deshabilitan cuando ya hay fusiones para no romper un
/// diseño personalizado: para retocarlo se usan Fusionar/Separar y arrastrar
/// líneas (o "Limpiar" para empezar de cero).
struct EditorControls: View {
    let model: EditorViewModel

    private var hasMerges: Bool { !model.merges.isEmpty }

    var body: some View {
        HStack(spacing: 20) {
            Stepper(
                "Columnas: \(model.columnCount)",
                value: Binding(get: { model.columnCount }, set: { model.setColumns($0) }),
                in: 1...8
            )
            .disabled(hasMerges)

            Stepper(
                "Filas: \(model.rowCount)",
                value: Binding(get: { model.rowCount }, set: { model.setRows($0) }),
                in: 1...8
            )
            .disabled(hasMerges)

            Spacer()

            Button("Fusionar", systemImage: "rectangle.on.rectangle") { model.mergeSelection() }
                .disabled(!model.canMerge)

            Button("Separar", systemImage: "rectangle.split.2x1") { model.unmergeSelection() }
                .disabled(!model.canUnmerge)

            Button("Limpiar", systemImage: "trash", role: .destructive) { model.clear() }
                .disabled(model.lines.isEmpty && model.merges.isEmpty)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    EditorControls(model: EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080)))
        .padding()
        .frame(width: 640)
}
