//
//  MonitorPreview.swift
//  ZoneSnap
//
//  UI — representación visual e interactiva del monitor con sus zonas.
//

import SwiftUI

/// Dibuja el área del monitor a escala con sus zonas numeradas y seleccionables.
/// La lógica vive en `EditorViewModel`; esta vista solo presenta y propaga la
/// selección.
struct MonitorPreview: View {
    let bounds: CGRect
    let zones: [Zone]
    var selectedZoneIDs: Set<Zone.ID> = []
    /// Callback al pulsar una zona: `(zoneID, extending)`. `nil` = no interactivo.
    var onSelectZone: ((Zone.ID, _ extending: Bool) -> Void)? = nil

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
            }
        }
        .aspectRatio(bounds.width / bounds.height, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 10))
        .accessibilityLabel("Vista previa del monitor con \(zones.count) zonas")
    }
}

#Preview("2x2 con selección") {
    let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let zones = ZoneCalculator.zones(in: bounds, lines: [
        GridLine(orientation: .vertical, position: 960),
        GridLine(orientation: .horizontal, position: 540)
    ])
    return MonitorPreview(bounds: bounds, zones: zones, selectedZoneIDs: [zones[3].id])
        .padding()
        .frame(width: 480, height: 300)
}
