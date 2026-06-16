//
//  EditorControls.swift
//  ZoneSnap
//
//  UI — controles del editor (columnas/filas de la selección, unir, limpiar).
//

import SwiftUI

/// Controles del editor. Operan sobre la **zona seleccionada** del
/// `EditorViewModel`: Columnas/Filas subdividen *esa* zona sin tocar el resto, y
/// se deshabilitan si no hay selección. "Unir" colapsa la franja de la
/// selección; "Limpiar" vuelve a una única zona.
struct EditorControls: View {
    let model: EditorViewModel

    var body: some View {
        HStack(spacing: 20) {
            Stepper(
                "Columnas: \(model.columnCount)",
                value: Binding(get: { model.columnCount }, set: { model.setColumns($0) }),
                in: 1...EditorViewModel.maxDivisions
            )
            .disabled(!model.hasSelection)

            Stepper(
                "Filas: \(model.rowCount)",
                value: Binding(get: { model.rowCount }, set: { model.setRows($0) }),
                in: 1...EditorViewModel.maxDivisions
            )
            .disabled(!model.hasSelection)

            Spacer()

            Button("Unir", systemImage: "rectangle.split.2x1") { model.uniteSelection() }
                .disabled(!model.canUnite)

            Button("Limpiar", systemImage: "trash", role: .destructive) { model.clear() }
                .disabled(model.previewZones.count <= 1)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    EditorControls(model: EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080)))
        .padding()
        .frame(width: 640)
}
