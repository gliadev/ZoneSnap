//
//  MonitorPreview.swift
//  ZoneSnap
//
//  UI — representación visual e interactiva del monitor con sus zonas.
//

import SwiftUI

/// Dibuja el área del monitor a escala con sus zonas (numeradas y seleccionables)
/// y las líneas divisorias arrastrables. La lógica vive en `EditorViewModel`;
/// esta vista solo presenta y propaga la interacción.
struct MonitorPreview: View {
    /// Nombre del espacio de coordenadas para mapear los arrastres de líneas.
    static let coordinateSpace = "monitorPreview"

    let bounds: CGRect
    let zones: [Zone]
    var lines: [GridLine] = []
    var selectedZoneIDs: Set<Zone.ID> = []
    /// Callback al pulsar una zona: `(zoneID, extending)`. `nil` = no interactivo.
    var onSelectZone: ((Zone.ID, _ extending: Bool) -> Void)? = nil
    /// Callback al arrastrar una línea: `(lineID, nuevaPosición)`. `nil` = sin arrastre.
    var onMoveLine: ((GridLine.ID, CGFloat) -> Void)? = nil
    /// Callback al soltar una línea fuera del borde (borrarla).
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
                        LineHandle(
                            line: line,
                            bounds: bounds,
                            scaleX: scaleX,
                            scaleY: scaleY,
                            size: proxy.size,
                            onMove: { onMoveLine(line.id, $0) },
                            onRemove: { onRemoveLine?(line.id) }
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

#Preview("3x2 con selección") {
    let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let lines = [
        GridLine(orientation: .vertical, position: 640),
        GridLine(orientation: .vertical, position: 1280),
        GridLine(orientation: .horizontal, position: 540)
    ]
    let zones = ZoneCalculator.zones(in: bounds, lines: lines)
    return MonitorPreview(
        bounds: bounds,
        zones: zones,
        lines: lines,
        selectedZoneIDs: [zones[4].id, zones[5].id],
        onSelectZone: { _, _ in },
        onMoveLine: { _, _ in },
        onRemoveLine: { _ in }
    )
    .padding()
    .frame(width: 520, height: 320)
}
