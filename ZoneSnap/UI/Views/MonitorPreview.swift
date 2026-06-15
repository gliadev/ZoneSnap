//
//  MonitorPreview.swift
//  ZoneSnap
//
//  UI — representación visual e interactiva del monitor con sus zonas.
//

import SwiftUI

/// Dibuja el área del monitor a escala con sus zonas (numeradas y seleccionables)
/// y las líneas divisorias arrastrables, **solo por los segmentos** donde separan
/// zonas distintas. La lógica vive en `EditorViewModel`.
struct MonitorPreview: View {
    /// Nombre del espacio de coordenadas para mapear los arrastres de líneas.
    static let coordinateSpace = "monitorPreview"

    let bounds: CGRect
    let zones: [Zone]
    var lines: [GridLine] = []
    var merges: [[GridCell]] = []
    var selectedZoneIDs: Set<Zone.ID> = []
    var onSelectZone: ((Zone.ID, _ extending: Bool) -> Void)? = nil
    var onMoveLine: ((GridLine.ID, CGFloat) -> Void)? = nil
    var onRemoveLine: ((GridLine.ID) -> Void)? = nil

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
                        isSelected: selectedZoneIDs.contains(zone.id),
                        onSelect: onSelectZone.map { handler in
                            { extending in handler(zone.id, extending) }
                        }
                    )
                    .frame(width: zone.rect.width * scaleX, height: zone.rect.height * scaleY)
                    .offset(
                        x: (zone.rect.minX - bounds.minX) * scaleX,
                        y: (zone.rect.minY - bounds.minY) * scaleY
                    )
                }

                if let onMoveLine {
                    ForEach(lines) { line in
                        let segments = ZoneCalculator.lineSegments(for: line, in: bounds, lines: lines, merges: merges)
                        ForEach(segments.indices, id: \.self) { index in
                            LineHandle(
                                line: line,
                                segment: segments[index],
                                bounds: bounds,
                                scaleX: scaleX,
                                scaleY: scaleY,
                                onMove: { onMoveLine(line.id, $0) },
                                onRemove: { onRemoveLine?(line.id) }
                            )
                        }
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

#Preview("fusión 1+2 sin línea cruzándola") {
    let bounds = CGRect(x: 0, y: 0, width: 900, height: 800)
    let lines = [
        GridLine(orientation: .vertical, position: 300),
        GridLine(orientation: .vertical, position: 600),
        GridLine(orientation: .horizontal, position: 400)
    ]
    let merges = [[GridCell(row: 0, col: 0), GridCell(row: 0, col: 1)]]
    let zones = ZoneCalculator.zones(in: bounds, lines: lines, merges: merges)
    return MonitorPreview(
        bounds: bounds,
        zones: zones,
        lines: lines,
        merges: merges,
        onSelectZone: { _, _ in },
        onMoveLine: { _, _ in },
        onRemoveLine: { _ in }
    )
    .padding()
    .frame(width: 520, height: 320)
}
