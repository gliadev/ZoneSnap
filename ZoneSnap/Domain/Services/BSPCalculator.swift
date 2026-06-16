//
//  BSPCalculator.swift
//  ZoneSnap
//
//  Domain — evaluación y transformación del árbol de zonas (ZoneNode).
//

import CoreGraphics
import Foundation

/// Lógica pura sobre el árbol `ZoneNode`: lo evalúa a `[Zone]` sobre un área y
/// ofrece transformaciones inmutables (subdividir, ajustar columnas/filas,
/// colapsar, mover fronteras), devolviendo siempre un árbol nuevo.
///
/// Trabaja en el espacio local del monitor (puntos, origen arriba-izquierda).
enum BSPCalculator {
    // MARK: - Evaluación

    /// Zonas (hojas) del árbol evaluado sobre `rect`, en orden de lectura
    /// (arriba→abajo, izquierda→derecha). La identidad de cada zona es la de su
    /// hoja, así que es estable al redimensionar.
    static func zones(of node: ZoneNode, in rect: CGRect) -> [Zone] {
        leaves(of: node, in: rect)
            .sorted { ($0.rect.minY, $0.rect.minX) < ($1.rect.minY, $1.rect.minX) }
    }

    /// Sub-rectángulos en que un split reparte `rect` según `ratios` (pesos
    /// relativos). Útil para situar las fronteras arrastrables en la UI.
    static func subrects(of rect: CGRect, axis: SplitAxis, ratios: [CGFloat]) -> [CGRect] {
        let total = ratios.reduce(0, +)
        guard total > 0 else { return [] }

        var rects: [CGRect] = []
        var offset: CGFloat = 0
        for ratio in ratios {
            let fraction = ratio / total
            switch axis {
            case .vertical:
                let width = rect.width * fraction
                rects.append(CGRect(x: rect.minX + offset, y: rect.minY, width: width, height: rect.height))
                offset += width
            case .horizontal:
                let height = rect.height * fraction
                rects.append(CGRect(x: rect.minX, y: rect.minY + offset, width: rect.width, height: height))
                offset += height
            }
        }
        return rects
    }

    // MARK: - Transformaciones

    /// Subdivide la hoja `id` en una rejilla de `columns` × `rows` (local; el
    /// resto del árbol no se toca). `1×1` no hace nada.
    static func subdivide(_ tree: ZoneNode, leaf id: UUID, columns: Int, rows: Int) -> ZoneNode {
        let cols = max(1, columns), rws = max(1, rows)
        guard cols > 1 || rws > 1 else { return tree }
        return replacing(id, in: tree) { _ in grid(columns: cols, rows: rws) }
    }

    /// Ajusta el número de **columnas** en el contexto de la hoja `id`:
    /// si su split padre es vertical, lo lleva a `count` columnas uniformes; si
    /// no, subdivide la propia hoja en `count` columnas. `count <= 1` colapsa.
    static func setColumns(_ tree: ZoneNode, forLeaf id: UUID, to count: Int) -> ZoneNode {
        setCount(tree, forLeaf: id, axis: .vertical, to: count)
    }

    /// Ídem para **filas** (split padre horizontal).
    static func setRows(_ tree: ZoneNode, forLeaf id: UUID, to count: Int) -> ZoneNode {
        setCount(tree, forLeaf: id, axis: .horizontal, to: count)
    }

    /// Colapsa el split que contiene directamente a la hoja `id`, reemplazándolo
    /// por una única hoja (deshace esa subdivisión = "unir"). Si la hoja es la
    /// raíz no hay nada que unir.
    static func collapseParent(_ node: ZoneNode, ofLeaf id: UUID) -> ZoneNode {
        guard case let .split(sid, axis, ratios, children) = node else { return node }
        if children.contains(where: { $0.id == id }) {
            return .leaf(id: UUID())
        }
        return .split(id: sid, axis: axis, ratios: ratios,
                      children: children.map { collapseParent($0, ofLeaf: id) })
    }

    /// Mueve la frontera interior `index` (entre el hijo `index` y el `index+1`)
    /// del split `id` a la fracción `position` (0…1) de su área, respetando un
    /// margen mínimo por hijo. Solo afecta a los dos hijos colindantes.
    static func moveBoundary(
        _ tree: ZoneNode,
        split id: UUID,
        boundary index: Int,
        toFraction position: CGFloat,
        minFraction: CGFloat = 0.05
    ) -> ZoneNode {
        replacing(id, in: tree) { node in
            guard case let .split(sid, axis, ratios, children) = node,
                  index >= 0, index < children.count - 1 else { return node }

            let total = ratios.reduce(0, +)
            let fractions = total > 0 ? ratios.map { $0 / total } : Array(repeating: 1 / CGFloat(ratios.count), count: ratios.count)
            var cuts = cumulative(fractions) // count = children.count - 1

            let lower = (index == 0 ? 0 : cuts[index - 1]) + minFraction
            let upper = (index == cuts.count - 1 ? 1 : cuts[index + 1]) - minFraction
            guard lower <= upper else { return node }
            cuts[index] = min(max(position, lower), upper)

            return .split(id: sid, axis: axis, ratios: fractionsFromCuts(cuts), children: children)
        }
    }

    // MARK: - Privado

    private static func leaves(of node: ZoneNode, in rect: CGRect) -> [Zone] {
        switch node {
        case let .leaf(id):
            return [Zone(id: id, rect: rect)]
        case let .split(_, axis, ratios, children):
            let rects = subrects(of: rect, axis: axis, ratios: ratios)
            return zip(children, rects).flatMap { leaves(of: $0, in: $1) }
        }
    }

    /// Devuelve un árbol nuevo aplicando `transform` al nodo cuyo id == `id`.
    private static func replacing(_ id: UUID, in node: ZoneNode, with transform: (ZoneNode) -> ZoneNode) -> ZoneNode {
        if node.id == id { return transform(node) }
        guard case let .split(sid, axis, ratios, children) = node else { return node }
        return .split(id: sid, axis: axis, ratios: ratios,
                      children: children.map { replacing(id, in: $0, with: transform) })
    }

    private static func setCount(_ tree: ZoneNode, forLeaf id: UUID, axis: SplitAxis, to count: Int) -> ZoneNode {
        let target = max(1, count)
        // Raíz hoja seleccionada: subdividir aquí mismo.
        if case let .leaf(leafID) = tree, leafID == id {
            return target == 1 ? tree : subdividedLeaf(axis: axis, count: target)
        }
        return adjustParent(tree, forLeaf: id, axis: axis, to: target)
    }

    private static func adjustParent(_ node: ZoneNode, forLeaf id: UUID, axis: SplitAxis, to count: Int) -> ZoneNode {
        guard case let .split(sid, splitAxis, ratios, children) = node else { return node }

        if let index = children.firstIndex(where: { $0.id == id && $0.isLeaf }) {
            if splitAxis == axis {
                return adjustingChildCount(sid: sid, axis: splitAxis, children: children, to: count)
            }
            var newChildren = children
            newChildren[index] = subdividedLeaf(axis: axis, count: count)
            return .split(id: sid, axis: splitAxis, ratios: ratios, children: newChildren)
        }

        return .split(id: sid, axis: splitAxis, ratios: ratios,
                      children: children.map { adjustParent($0, forLeaf: id, axis: axis, to: count) })
    }

    private static func adjustingChildCount(sid: UUID, axis: SplitAxis, children: [ZoneNode], to count: Int) -> ZoneNode {
        guard count > 1 else { return .leaf(id: UUID()) }
        var newChildren = children
        if count < children.count {
            newChildren = Array(children.prefix(count))
        } else if count > children.count {
            newChildren += (children.count..<count).map { _ in ZoneNode.leaf(id: UUID()) }
        }
        return .split(id: sid, axis: axis, ratios: Array(repeating: 1, count: count), children: newChildren)
    }

    private static func subdividedLeaf(axis: SplitAxis, count: Int) -> ZoneNode {
        count <= 1
            ? .leaf(id: UUID())
            : .split(id: UUID(), axis: axis, ratios: Array(repeating: 1, count: count),
                     children: (0..<count).map { _ in ZoneNode.leaf(id: UUID()) })
    }

    private static func grid(columns: Int, rows: Int) -> ZoneNode {
        func row() -> ZoneNode { subdividedLeaf(axis: .vertical, count: columns) }
        if rows == 1 { return row() }
        return .split(id: UUID(), axis: .horizontal, ratios: Array(repeating: 1, count: rows),
                      children: (0..<rows).map { _ in row() })
    }

    /// Posiciones acumuladas de las fronteras interiores (sin el 0 ni el 1).
    private static func cumulative(_ fractions: [CGFloat]) -> [CGFloat] {
        guard fractions.count > 1 else { return [] }
        var sum: CGFloat = 0
        var cuts: [CGFloat] = []
        for fraction in fractions.dropLast() {
            sum += fraction
            cuts.append(sum)
        }
        return cuts
    }

    /// Reconstruye las fracciones de cada hijo a partir de las fronteras interiores.
    private static func fractionsFromCuts(_ cuts: [CGFloat]) -> [CGFloat] {
        guard !cuts.isEmpty else { return [1] }
        var fractions: [CGFloat] = [cuts[0]]
        for index in 1..<cuts.count {
            fractions.append(cuts[index] - cuts[index - 1])
        }
        fractions.append(1 - cuts[cuts.count - 1])
        return fractions
    }
}
