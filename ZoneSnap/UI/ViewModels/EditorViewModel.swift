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

    /// Zonas seleccionadas (para resaltar y para colocar una ventana sobre ellas).
    private(set) var selectedZoneIDs: Set<Zone.ID> = []

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
        // Las zonas cambiaron: sus ids previos ya no son válidos.
        selectedZoneIDs.removeAll()
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
        for index in 1..<clamped {
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
        for index in 1..<clamped {
            let y = bounds.minY + bounds.height * CGFloat(index) / CGFloat(clamped)
            lines.append(GridLine(orientation: .horizontal, position: y))
        }
        recompute()
    }
}

// MARK: - Edición libre de líneas

extension EditorViewModel {
    /// Separación de "snap" al arrastrar líneas (puntos del monitor).
    static let lineSnapStep: CGFloat = 8

    /// Margen mínimo de una línea respecto al borde, para no crear zonas
    /// degeneradas.
    static let lineMinMargin: CGFloat = 24

    /// Reposiciona una línea (al arrastrarla). La posición se ajusta al step de
    /// snap y se mantiene dentro del área con un margen mínimo. No-op si el id
    /// no existe.
    func moveLine(_ id: GridLine.ID, to position: CGFloat) {
        guard let index = lines.firstIndex(where: { $0.id == id }) else { return }
        let isVertical = lines[index].orientation == .vertical
        let lower = (isVertical ? bounds.minX : bounds.minY) + Self.lineMinMargin
        let upper = (isVertical ? bounds.maxX : bounds.maxY) - Self.lineMinMargin
        let snapped = (position / Self.lineSnapStep).rounded() * Self.lineSnapStep
        lines[index].position = min(max(snapped, lower), upper)
        recompute()
    }
}

// MARK: - Carga desde zonas persistidas

extension EditorViewModel {
    /// Reconstruye las líneas a partir de un conjunto de zonas alineadas a
    /// rejilla (las que produce el propio editor): toma los bordes internos
    /// como líneas. Para zonas no alineadas la reconstrucción es aproximada.
    func load(_ zones: [Zone]) {
        guard !zones.isEmpty else {
            clear()
            return
        }
        let internalXs = Set(zones.flatMap { [$0.rect.minX, $0.rect.maxX] })
            .subtracting([bounds.minX, bounds.maxX])
        let internalYs = Set(zones.flatMap { [$0.rect.minY, $0.rect.maxY] })
            .subtracting([bounds.minY, bounds.maxY])

        lines = internalXs.sorted().map { GridLine(orientation: .vertical, position: $0) }
            + internalYs.sorted().map { GridLine(orientation: .horizontal, position: $0) }
        recompute()
    }
}

// MARK: - Selección de zonas

extension EditorViewModel {
    /// Zonas seleccionadas, en el orden de la preview.
    var selectedZones: [Zone] {
        previewZones.filter { selectedZoneIDs.contains($0.id) }
    }

    /// Rectángulo que engloba la selección (espacio local del monitor), o `nil`
    /// si no hay nada seleccionado.
    var selectionRect: CGRect? {
        WindowFrameCalculator.boundingRect(of: selectedZones)
    }

    /// Selecciona una zona. Con `extending` (Shift) alterna su pertenencia a la
    /// selección; sin `extending` deja solo esa zona (o limpia si ya era la única).
    func selectZone(_ id: Zone.ID, extending: Bool) {
        if extending {
            if selectedZoneIDs.contains(id) {
                selectedZoneIDs.remove(id)
            } else {
                selectedZoneIDs.insert(id)
            }
        } else {
            selectedZoneIDs = (selectedZoneIDs == [id]) ? [] : [id]
        }
    }

    /// Limpia la selección.
    func clearSelection() {
        selectedZoneIDs.removeAll()
    }
}
