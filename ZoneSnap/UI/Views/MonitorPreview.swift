//
//  MonitorPreview.swift
//  ZoneSnap
//
//  UI — representación visual e interactiva del monitor con sus zonas.
//

import SwiftUI

/// Dibuja el área del monitor a escala con sus zonas (numeradas y seleccionables)
/// y los separadores arrastrables entre ellas. La lógica vive en `EditorViewModel`.
struct MonitorPreview: View {
    /// Nombre del espacio de coordenadas para mapear los arrastres de separadores.
    static let coordinateSpace = "monitorPreview"

    let bounds: CGRect
    let zones: [Zone]
    var boundaries: [Boundary] = []
    var selectedZoneID: Zone.ID? = nil
    var onSelectZone: ((Zone.ID) -> Void)? = nil
    var onMoveBoundary: ((Boundary, CGFloat) -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            let scaleX = proxy.size.width / bounds.width
            let scaleY = proxy.size.height / bounds.height

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.85)

                // `Array(...)` porque EnumeratedSequence solo es RandomAccessCollection en macOS 26+.
                ForEach(Array(zones.enumerated()), id: \.element.id) { index, zone in
                    ZoneCell(
                        number: index + 1,
                        isSelected: zone.id == selectedZoneID,
                        onSelect: onSelectZone.map { handler in { _ in handler(zone.id) } }
                    )
                    .frame(width: zone.rect.width * scaleX, height: zone.rect.height * scaleY)
                    .offset(
                        x: (zone.rect.minX - bounds.minX) * scaleX,
                        y: (zone.rect.minY - bounds.minY) * scaleY
                    )
                }

                if let onMoveBoundary {
                    ForEach(boundaries) { boundary in
                        BoundaryHandle(
                            boundary: boundary,
                            bounds: bounds,
                            scaleX: scaleX,
                            scaleY: scaleY,
                            onMove: { onMoveBoundary(boundary, $0) }
                        )
                    }
                }
            }
            .coordinateSpace(.named(Self.coordinateSpace))
        }
        .aspectRatio(bounds.width / bounds.height, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 10))
        .accessibilityLabel("Vista previa del monitor con \(zones.count) zonas")
    }
}

#Preview("rejilla 2×2 con un cuadrante subdividido") {
    let bounds = CGRect(x: 0, y: 0, width: 900, height: 800)
    // Cuadrante superior-derecho partido en 2 filas (subdivisión local).
    let tree = ZoneNode.split(id: UUID(), axis: .horizontal, ratios: [1, 1], children: [
        .split(id: UUID(), axis: .vertical, ratios: [1, 1], children: [
            .leaf(id: UUID()),
            .split(id: UUID(), axis: .horizontal, ratios: [1, 1], children: [.leaf(id: UUID()), .leaf(id: UUID())])
        ]),
        .split(id: UUID(), axis: .vertical, ratios: [1, 1], children: [.leaf(id: UUID()), .leaf(id: UUID())])
    ])
    return MonitorPreview(
        bounds: bounds,
        zones: BSPCalculator.zones(of: tree, in: bounds),
        boundaries: BSPCalculator.boundaries(of: tree, in: bounds),
        onSelectZone: { _ in },
        onMoveBoundary: { _, _ in }
    )
    .padding()
    .frame(width: 520, height: 460)
}
