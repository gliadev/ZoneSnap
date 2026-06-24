//
//  EditorViewModel.swift
//  ZoneSnap
//
//  UI — estado y lógica del editor de zonas (testeable sin UI).
//

import CoreGraphics
import Foundation
import Observation

/// Estado y lógica del editor de zonas, sobre el árbol de subdivisión
/// (`ZoneNode`). Mantiene el árbol como fuente de verdad y deriva la preview de
/// zonas y las fronteras arrastrables con `BSPCalculator`.
///
/// Las operaciones de columnas/filas son **locales a la zona seleccionada**:
/// subdividir o ajustar una franja no toca el resto del diseño. Trabaja en el
/// espacio local del monitor (puntos, origen arriba-izquierda).
@MainActor
@Observable
final class EditorViewModel {
    private(set) var bounds: CGRect
    private(set) var tree: ZoneNode
    private(set) var previewZones: [Zone] = []
    private(set) var boundaries: [Boundary] = []

    /// Zona (hoja) seleccionada para subdividir, unir o colocar una ventana.
    private(set) var selectedZoneID: Zone.ID?

    /// Fracción mínima por hijo al arrastrar una frontera (evita zonas de 0px).
    static let minBoundaryFraction: CGFloat = 0.04
    /// Tope de columnas/filas por franja en los steppers.
    static let maxDivisions = 8

    init(bounds: CGRect) {
        self.bounds = bounds
        self.tree = .leaf(id: UUID())
        recompute()
    }

    func updateBounds(_ newBounds: CGRect) {
        bounds = newBounds
        recompute()
    }

    /// Vuelve a una única zona (toda el área).
    func clear() {
        tree = .leaf(id: UUID())
        selectedZoneID = nil
        recompute()
    }

    private func recompute() {
        previewZones = BSPCalculator.zones(of: tree, in: bounds)
        boundaries = BSPCalculator.boundaries(of: tree, in: bounds)
        if let id = selectedZoneID, !previewZones.contains(where: { $0.id == id }) {
            selectedZoneID = nil
        }
    }
}

// MARK: - Selección

extension EditorViewModel {
    var selectedZone: Zone? {
        previewZones.first { $0.id == selectedZoneID }
    }

    /// Rect de la zona seleccionada (destino al mover una ventana).
    var selectionRect: CGRect? {
        selectedZone?.rect
    }

    /// Click sobre una zona: la selecciona; click de nuevo la deselecciona.
    func selectZone(_ id: Zone.ID) {
        selectedZoneID = (selectedZoneID == id) ? nil : id
    }

    func clearSelection() {
        selectedZoneID = nil
    }

    private func selectFirstZoneIn(_ rect: CGRect) {
        if let zone = previewZones.first(where: { $0.rect.intersects(rect) || rect.contains($0.rect) }) {
            selectedZoneID = zone.id
        }
    }
}

// MARK: - Subdivisión local (columnas / filas)

extension EditorViewModel {
    /// Hay una zona seleccionada sobre la que subdividir.
    var hasSelection: Bool { selectedZoneID != nil }

    /// Columnas de la franja de la zona seleccionada (1 si no está dividida en columnas).
    var columnCount: Int {
        guard let id = selectedZoneID else { return 1 }
        return BSPCalculator.childCount(of: tree, forLeaf: id, axis: .vertical)
    }

    /// Filas de la franja de la zona seleccionada.
    var rowCount: Int {
        guard let id = selectedZoneID else { return 1 }
        return BSPCalculator.childCount(of: tree, forLeaf: id, axis: .horizontal)
    }

    /// Ajusta las columnas de la zona seleccionada (local; no toca el resto).
    func setColumns(_ count: Int) {
        guard let id = selectedZoneID, let prevRect = selectedZone?.rect else { return }
        tree = BSPCalculator.setColumns(tree, forLeaf: id, to: clampDivisions(count))
        recompute()
        selectFirstZoneIn(prevRect)
    }

    /// Ajusta las filas de la zona seleccionada.
    func setRows(_ count: Int) {
        guard let id = selectedZoneID, let prevRect = selectedZone?.rect else { return }
        tree = BSPCalculator.setRows(tree, forLeaf: id, to: clampDivisions(count))
        recompute()
        selectFirstZoneIn(prevRect)
    }

    /// Subdivide la zona seleccionada en una rejilla `columns × rows`.
    func subdivideSelection(columns: Int, rows: Int) {
        guard let id = selectedZoneID else { return }
        tree = BSPCalculator.subdivide(tree, leaf: id,
                                       columns: clampDivisions(columns),
                                       rows: clampDivisions(rows))
        recompute()
    }

    /// Se puede unir: la zona seleccionada pertenece a un split (no es la raíz sola).
    var canUnite: Bool {
        guard selectedZoneID != nil, case .split = tree else { return false }
        return true
    }

    /// Une (colapsa) la franja que contiene la zona seleccionada en una sola zona.
    func uniteSelection() {
        guard let id = selectedZoneID else { return }
        tree = BSPCalculator.collapseParent(tree, ofLeaf: id)
        recompute()
    }

    private func clampDivisions(_ value: Int) -> Int {
        min(max(1, value), Self.maxDivisions)
    }
}

// MARK: - Mover fronteras

extension EditorViewModel {
    /// Mueve una frontera al arrastrarla. `position` es la coordenada local
    /// (`x` para verticales, `y` para horizontales).
    func moveBoundary(_ boundary: Boundary, to position: CGFloat) {
        let span = boundary.extent.upperBound - boundary.extent.lowerBound
        guard span > 0 else { return }
        let fraction = (position - boundary.extent.lowerBound) / span
        tree = BSPCalculator.moveBoundary(tree, split: boundary.splitID, boundary: boundary.index,
                                          toFraction: fraction, minFraction: Self.minBoundaryFraction)
        recompute()
    }
}

// MARK: - Persistencia / compatibilidad

extension EditorViewModel {
    /// Restaura el árbol guardado.
    func applyTree(_ newTree: ZoneNode) {
        tree = newTree
        selectedZoneID = nil
        recompute()
    }

    /// Compat con configuraciones antiguas guardadas como rejilla de zonas:
    /// reconstruye el árbol si la partición es guillotina; si no, una sola zona.
    func load(_ zones: [Zone]) {
        tree = BSPCalculator.tree(fromGrid: zones, in: bounds) ?? .leaf(id: UUID())
        selectedZoneID = nil
        recompute()
    }
}
