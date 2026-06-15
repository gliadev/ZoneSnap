//
//  LineHandle.swift
//  ZoneSnap
//
//  UI — manija arrastrable de una línea divisoria del editor.
//

import SwiftUI

/// Barra arrastrable que representa una línea divisoria. El área de arrastre es
/// más ancha que la línea visible para facilitar el agarre. Informa la nueva
/// posición mientras se arrastra y, si se suelta fuera del área, pide borrarla.
struct LineHandle: View {
    let line: GridLine
    let bounds: CGRect
    let scaleX: CGFloat
    let scaleY: CGFloat
    let size: CGSize
    let onMove: (CGFloat) -> Void
    let onRemove: () -> Void

    private var isVertical: Bool { line.orientation == .vertical }

    var body: some View {
        let center = isVertical
            ? CGPoint(x: (line.position - bounds.minX) * scaleX, y: size.height / 2)
            : CGPoint(x: size.width / 2, y: (line.position - bounds.minY) * scaleY)

        Rectangle()
            .fill(.white.opacity(0.9))
            .frame(
                width: isVertical ? 2 : size.width,
                height: isVertical ? size.height : 2
            )
            .frame(
                width: isVertical ? 18 : size.width,
                height: isVertical ? size.height : 18
            )
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

    /// Posición del arrastre en coordenadas locales del monitor.
    private func localPosition(of value: DragGesture.Value) -> CGFloat {
        isVertical
            ? value.location.x / scaleX + bounds.minX
            : value.location.y / scaleY + bounds.minY
    }

    /// `true` si la posición cae fuera del área (arrastrada fuera del borde).
    private func isOutsideBounds(_ position: CGFloat) -> Bool {
        isVertical
            ? position < bounds.minX || position > bounds.maxX
            : position < bounds.minY || position > bounds.maxY
    }
}
