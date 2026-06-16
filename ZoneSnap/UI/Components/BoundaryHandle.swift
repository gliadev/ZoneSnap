//
//  BoundaryHandle.swift
//  ZoneSnap
//
//  UI — separador arrastrable entre dos zonas (frontera de un split).
//

import SwiftUI

/// Barra arrastrable que representa una `Boundary` (frontera interior de un
/// split). El área de agarre es más ancha que la línea visible. Arrastrarla
/// redimensiona solo las dos zonas colindantes; nunca cruza zonas ajenas porque
/// la frontera solo abarca el área de su split.
struct BoundaryHandle: View {
    let boundary: Boundary
    let bounds: CGRect
    let scaleX: CGFloat
    let scaleY: CGFloat
    let onMove: (CGFloat) -> Void

    private var isVertical: Bool { boundary.axis == .vertical }

    var body: some View {
        let lengthScale = isVertical ? scaleY : scaleX
        let length = (boundary.span.upperBound - boundary.span.lowerBound) * lengthScale
        let crossPosition = isVertical
            ? (boundary.position - bounds.minX) * scaleX
            : (boundary.position - bounds.minY) * scaleY
        let alongCenter = isVertical
            ? ((boundary.span.lowerBound + boundary.span.upperBound) / 2 - bounds.minY) * scaleY
            : ((boundary.span.lowerBound + boundary.span.upperBound) / 2 - bounds.minX) * scaleX
        let center = isVertical
            ? CGPoint(x: crossPosition, y: alongCenter)
            : CGPoint(x: alongCenter, y: crossPosition)

        Rectangle()
            .fill(.white.opacity(0.9))
            .frame(width: isVertical ? 2 : length, height: isVertical ? length : 2)
            .frame(width: isVertical ? 18 : length, height: isVertical ? length : 18)
            .contentShape(.rect)
            .position(center)
            .gesture(
                DragGesture(coordinateSpace: .named(MonitorPreview.coordinateSpace))
                    .onChanged { value in onMove(localPosition(of: value)) }
            )
    }

    private func localPosition(of value: DragGesture.Value) -> CGFloat {
        isVertical
            ? value.location.x / scaleX + bounds.minX
            : value.location.y / scaleY + bounds.minY
    }
}
