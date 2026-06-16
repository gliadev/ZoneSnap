//
//  ZoneOverlayView.swift
//  ZoneSnap
//
//  UI — overlay transparente que ilumina las zonas sobre el monitor.
//

import SwiftUI

/// Dibuja las zonas iluminadas sobre un fondo transparente y resalta la(s) que
/// están bajo el cursor (una o varias en span). Pensada para ir dentro de una
/// ventana-overlay a tamaño del monitor (F4b).
struct ZoneOverlayView: View {
    let model: OverlayModel

    var body: some View {
        GeometryReader { proxy in
            let scaleX = proxy.size.width / model.bounds.width
            let scaleY = proxy.size.height / model.bounds.height

            ZStack(alignment: .topLeading) {
                Color.clear

                ForEach(model.zones) { zone in
                    let isHot = model.highlightedZoneIDs.contains(zone.id)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor.opacity(isHot ? 0.35 : 0.10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.accentColor.opacity(isHot ? 1 : 0.45), lineWidth: isHot ? 5 : 2)
                        }
                        .frame(width: zone.rect.width * scaleX, height: zone.rect.height * scaleY)
                        .offset(
                            x: (zone.rect.minX - model.bounds.minX) * scaleX,
                            y: (zone.rect.minY - model.bounds.minY) * scaleY
                        )
                }
            }
            .animation(.easeOut(duration: 0.12), value: model.highlightedZoneIDs)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview("overlay con span de 2 zonas") {
    let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let zones = ZoneCalculator.zones(in: bounds, lines: [
        GridLine(orientation: .vertical, position: 640),
        GridLine(orientation: .vertical, position: 1280),
        GridLine(orientation: .horizontal, position: 540)
    ])
    let model = OverlayModel()
    model.configure(bounds: bounds, zones: zones)
    model.highlightedZoneIDs = [zones[4].id, zones[5].id]
    return ZoneOverlayView(model: model)
        .frame(width: 520, height: 300)
        .background(.black)
}
