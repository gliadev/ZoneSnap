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
/// Mantiene las líneas divisorias (y opcionalmente fusiones de celdas) y
/// recalcula la preview de zonas con `ZoneCalculator` ante cada cambio. Trabaja
/// en el espacio local del monitor (puntos, origen arriba-izquierda).
@MainActor
@Observable
final class EditorViewModel {
    private(set) var bounds: CGRect
    private(set) var lines: [GridLine] = []
    private(set) var merges: [[GridCell]] = []
    private(set) var previewZones: [Zone] = []

    /// Zonas seleccionadas (para resaltar, fusionar y colocar ventanas).
    private(set) var selectedZoneIDs: Set<Zone.ID> = []

    init(bounds: CGRect) {
        self.bounds = bounds
        recompute()
    }

    func updateBounds(_ newBounds: CGRect) {
        bounds = newBounds
        recompute()
    }

    func addLine(_ orientation: LineOrientation, at position: CGFloat) {
        lines.append(GridLine(orientation: orientation, position: position))
        merges.removeAll() // cambia la rejilla → las fusiones dejan de ser válidas
        recompute()
    }

    func removeLine(_ id: GridLine.ID) {
        lines.removeAll { $0.id == id }
        merges.removeAll()
        recompute()
    }

    /// Borra líneas y fusiones (vuelve a una única zona = el área completa).
    func clear() {
        lines.removeAll()
        merges.removeAll()
        recompute()
    }

    private func recompute() {
        previewZones = ZoneCalculator.zones(in: bounds, lines: lines, merges: merges)
        selectedZoneIDs.removeAll()
    }
}

// MARK: - Presets de rejilla

extension EditorViewModel {
    var columnCount: Int {
        lines.filter { $0.orientation == .vertical }.count + 1
    }

    var rowCount: Int {
        lines.filter { $0.orientation == .horizontal }.count + 1
    }

    func setColumns(_ columns: Int) {
        let clamped = max(1, columns)
        lines.removeAll { $0.orientation == .vertical }
        for index in 1..<clamped {
            lines.append(GridLine(orientation: .vertical, position: bounds.minX + bounds.width * CGFloat(index) / CGFloat(clamped)))
        }
        merges.removeAll()
        recompute()
    }

    func setRows(_ rows: Int) {
        let clamped = max(1, rows)
        lines.removeAll { $0.orientation == .horizontal }
        for index in 1..<clamped {
            lines.append(GridLine(orientation: .horizontal, position: bounds.minY + bounds.height * CGFloat(index) / CGFloat(clamped)))
        }
        merges.removeAll()
        recompute()
    }
}

// MARK: - Edición libre de líneas

extension EditorViewModel {
    static let lineSnapStep: CGFloat = 8
    static let lineMinMargin: CGFloat = 24

    /// Reposiciona una línea (al arrastrarla). Mantiene las fusiones (no cambia
    /// la estructura de celdas, solo su tamaño).
    func moveLine(_ id: GridLine.ID, to position: CGFloat) {
        guard let index = lines.firstIndex(where: { $0.id == id }) else { return }
        let isVertical = lines[index].orientation == .vertical
        let lower = (isVertical ? bounds.minX : bounds.minY) + Self.lineMinMargin
        let upper = (isVertical ? bounds.maxX : bounds.maxY) - Self.lineMinMargin
        let snapped = (position / Self.lineSnapStep).rounded() * Self.lineSnapStep
        lines[index].position = min(max(snapped, lower), upper)
        recompute()
    }

    /// Sustituye todas las líneas por las dadas (al aplicar un perfil). Resetea fusiones.
    func applyLines(_ newLines: [GridLine]) {
        lines = newLines
        merges.removeAll()
        recompute()
    }

    /// Restaura el modelo completo del editor (líneas + fusiones) desde persistencia.
    func applyModel(lines newLines: [GridLine], merges newMerges: [[GridCell]]) {
        lines = newLines
        merges = newMerges
        recompute()
    }
}

// MARK: - Carga desde zonas persistidas

extension EditorViewModel {
    /// Reconstruye las líneas a partir de zonas alineadas a rejilla (compat con
    /// configuraciones antiguas sin modelo de editor guardado).
    func load(_ zones: [Zone]) {
        guard !zones.isEmpty else {
            clear()
            return
        }
        let internalXs = Set(zones.flatMap { [$0.rect.minX, $0.rect.maxX] }).subtracting([bounds.minX, bounds.maxX])
        let internalYs = Set(zones.flatMap { [$0.rect.minY, $0.rect.maxY] }).subtracting([bounds.minY, bounds.maxY])

        lines = internalXs.sorted().map { GridLine(orientation: .vertical, position: $0) }
            + internalYs.sorted().map { GridLine(orientation: .horizontal, position: $0) }
        merges.removeAll()
        recompute()
    }
}

// MARK: - Selección de zonas

extension EditorViewModel {
    var selectedZones: [Zone] {
        previewZones.filter { selectedZoneIDs.contains($0.id) }
    }

    var selectionRect: CGRect? {
        WindowFrameCalculator.boundingRect(of: selectedZones)
    }

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

    func clearSelection() {
        selectedZoneIDs.removeAll()
    }
}

// MARK: - Fusión de celdas

extension EditorViewModel {
    /// Hay ≥2 zonas seleccionadas (se pueden fusionar).
    var canMerge: Bool {
        selectedZoneIDs.count >= 2
    }

    /// Alguna zona seleccionada es una zona fusionada (se puede separar).
    var canUnmerge: Bool {
        !selectedZoneIDs.isDisjoint(with: mergedZoneIDs)
    }

    /// Fusiona las zonas seleccionadas en una sola (su bounding box de celdas).
    func mergeSelection() {
        guard let union = WindowFrameCalculator.boundingRect(of: selectedZones) else { return }
        let cells = ZoneCalculator.cells(in: bounds, lines: lines)
            .filter { union.contains(CGPoint(x: $0.rect.midX, y: $0.rect.midY)) }
            .map(\.cell)
        guard cells.count > 1 else { return }

        let group = Set(cells)
        merges.removeAll { !Set($0).isDisjoint(with: group) } // quita fusiones solapadas
        merges.append(cells)
        recompute()
    }

    /// Separa (deshace la fusión de) las zonas fusionadas seleccionadas.
    func unmergeSelection() {
        let ids = selectedZoneIDs
        merges.removeAll { group in
            guard let anchor = group.min(by: { ($0.row, $0.col) < ($1.row, $1.col) }) else { return false }
            return ids.contains(ZoneCalculator.zoneID(for: anchor))
        }
        recompute()
    }

    /// Ids de las zonas que son fruto de una fusión.
    private var mergedZoneIDs: Set<Zone.ID> {
        Set(merges.compactMap { group in
            group.min(by: { ($0.row, $0.col) < ($1.row, $1.col) }).map(ZoneCalculator.zoneID(for:))
        })
    }
}
