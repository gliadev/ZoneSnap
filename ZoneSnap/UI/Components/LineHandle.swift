//
//  LineHandle.swift
//  ZoneSnap
//
//  UI — manija arrastrable de un segmento de línea divisoria.
//

import SwiftUI

/// Barra arrastrable que representa un **segmento** de una línea divisoria (solo
/// donde separa dos zonas distintas). El área de arrastre es más ancha que la
/// línea visible. Arrastrar mueve toda la línea; soltar fuera del borde la borra.
struct LineHandle: View {
    let line: GridLine
    /// Rango del segmento en coordenadas locales: `y` (verticales) o `x` (horizontales).
    let segment: ClosedRange<CGFloat>
    let bounds: CGRect
    let scaleX: CGFloat
    let scaleY: CGFloat
    let onMove: (CGFloat) -> Void
    let onRemove: () -> Void

    private var isVertical: Bool { line.orientation == .vertical }

    var body: some View {
        let lengthScale = isVertical ? scaleY : scaleX
        let length = (segment.upperBound - segment.lowerBound) * lengthScale
        let crossPosition = isVertical
            ? (line.position - bounds.minX) * scaleX
            : (line.position - bounds.minY) * scaleY
        let alongCenter = isVertical
            ? ((segment.lowerBound + segment.upperBound) / 2 - bounds.minY) * scaleY
            : ((segment.lowerBound + segment.upperBound) / 2 - bounds.minX) * scaleX
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
                    .onEnded { value in
                        if isOutsideBounds(localPosition(of: value)) { onRemove() }
                    }
            )
    }

    private func localPosition(of value: DragGesture.Value) -> CGFloat {
        isVertical
            ? value.location.x / scaleX + bounds.minX
            : value.location.y / scaleY + bounds.minY
    }

    private func isOutsideBounds(_ position: CGFloat) -> Bool {
        isVertical
            ? position < bounds.minX || position > bounds.maxX
            : position < bounds.minY || position > bounds.maxY
    }
}
