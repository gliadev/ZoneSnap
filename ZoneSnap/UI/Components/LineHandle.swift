//
//  LineHandle.swift
//  ZoneSnap
//
//  UI — manija arrastrable de una línea divisoria del editor.
//

import SwiftUI

/// Barra arrastrable que representa una línea divisoria. El área de arrastre es
/// más ancha que la línea visible para facilitar el agarre. Informa la nueva
/// posición (en coordenadas locales del monitor) mientras se arrastra.
struct LineHandle: View {
    let line: GridLine
    let bounds: CGRect
    let scaleX: CGFloat
    let scaleY: CGFloat
    let size: CGSize
    let onMove: (CGFloat) -> Void

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
                    .onChanged { value in
                        let local = isVertical
                            ? value.location.x / scaleX + bounds.minX
                            : value.location.y / scaleY + bounds.minY
                        onMove(local)
                    }
            )
    }
}
