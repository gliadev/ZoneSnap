//
//  EditorViewModel.swift
//  ZoneSnap
//
//  UI — estado y lógica del editor de zonas (testeable sin UI).
//

import CoreGraphics
import Foundation
import Observation

/// Estado y lógica del editor de zonas.
///
/// Mantiene las líneas divisorias y recalcula la preview de zonas con
/// `ZoneCalculator` ante cada cambio. Trabaja en el espacio local del monitor
/// (puntos, origen arriba-izquierda). `previewZones` se almacena (no se calcula
/// al vuelo) para que sus identidades sean estables entre renders de SwiftUI.
@MainActor
@Observable
final class EditorViewModel {
    private(set) var bounds: CGRect
    private(set) var lines: [GridLine] = []
    private(set) var previewZones: [Zone] = []

    init(bounds: CGRect) {
        self.bounds = bounds
        recompute()
    }

    /// Actualiza el área de trabajo (p. ej. al cambiar de monitor).
    func updateBounds(_ newBounds: CGRect) {
        bounds = newBounds
        recompute()
    }

    /// Añade una línea divisoria en la posición dada (espacio local del monitor).
    func addLine(_ orientation: LineOrientation, at position: CGFloat) {
        lines.append(GridLine(orientation: orientation, position: position))
        recompute()
    }

    /// Elimina la línea con el id indicado.
    func removeLine(_ id: GridLine.ID) {
        lines.removeAll { $0.id == id }
        recompute()
    }

    /// Borra todas las líneas (vuelve a una única zona = el área completa).
    func clear() {
        lines.removeAll()
        recompute()
    }

    private func recompute() {
        previewZones = ZoneCalculator.zones(in: bounds, lines: lines)
    }
}

// MARK: - Presets de rejilla

extension EditorViewModel {
    /// Columnas actuales (líneas verticales + 1).
    var columnCount: Int {
        lines.filter { $0.orientation == .vertical }.count + 1
    }

    /// Filas actuales (líneas horizontales + 1).
    var rowCount: Int {
        lines.filter { $0.orientation == .horizontal }.count + 1
    }

    /// Reparte el área en `columns` columnas iguales (mínimo 1), sustituyendo
    /// las líneas verticales actuales.
    func setColumns(_ columns: Int) {
        let clamped = max(1, columns)
        lines.removeAll { $0.orientation == .vertical }
        for index in 1..<max(1, clamped) where clamped > 1 {
            let x = bounds.minX + bounds.width * CGFloat(index) / CGFloat(clamped)
            lines.append(GridLine(orientation: .vertical, position: x))
        }
        recompute()
    }

    /// Reparte el área en `rows` filas iguales (mínimo 1), sustituyendo las
    /// líneas horizontales actuales.
    func setRows(_ rows: Int) {
        let clamped = max(1, rows)
        lines.removeAll { $0.orientation == .horizontal }
        for index in 1..<max(1, clamped) where clamped > 1 {
            let y = bounds.minY + bounds.height * CGFloat(index) / CGFloat(clamped)
            lines.append(GridLine(orientation: .horizontal, position: y))
        }
        recompute()
    }
}
