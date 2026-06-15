//
//  MonitorPreview.swift
//  ZoneSnap
//
//  UI — representación visual del monitor con sus zonas y líneas.
//

import SwiftUI

/// Dibuja el área del monitor a escala, con sus zonas numeradas y las líneas
/// divisorias. Solo presenta; la lógica vive en `EditorViewModel`.
///
/// Usa `Canvas` para escalar el espacio local del monitor (`bounds`) al tamaño
/// disponible, evitando `GeometryReader`.
struct MonitorPreview: View {
    let bounds: CGRect
    let zones: [Zone]
    let lines: [GridLine]

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / bounds.width
            let scaleY = size.height / bounds.height

            for (index, zone) in zones.enumerated() {
                draw(zone, number: index + 1, in: &context, scaleX: scaleX, scaleY: scaleY)
            }
            for line in lines {
                draw(line, in: &context, size: size, scaleX: scaleX, scaleY: scaleY)
            }
        }
        .background(.black.opacity(0.85))
        .clipShape(.rect(cornerRadius: 10))
        .aspectRatio(bounds.width / bounds.height, contentMode: .fit)
        .accessibilityLabel("Vista previa del monitor con \(zones.count) zonas")
    }

    private func draw(
        _ zone: Zone,
        number: Int,
        in context: inout GraphicsContext,
        scaleX: CGFloat,
        scaleY: CGFloat
    ) {
        let rect = CGRect(
            x: (zone.rect.minX - bounds.minX) * scaleX,
            y: (zone.rect.minY - bounds.minY) * scaleY,
            width: zone.rect.width * scaleX,
            height: zone.rect.height * scaleY
        ).insetBy(dx: 3, dy: 3)

        let shape = Path(roundedRect: rect, cornerRadius: 6)
        context.fill(shape, with: .color(.accentColor.opacity(0.18)))
        context.stroke(shape, with: .color(.accentColor), lineWidth: 1.5)

        var label = context.resolve(Text("\(number)").font(.headline.bold()))
        label.shading = .color(.white)
        context.draw(label, at: CGPoint(x: rect.midX, y: rect.midY))
    }

    private func draw(
        _ line: GridLine,
        in context: inout GraphicsContext,
        size: CGSize,
        scaleX: CGFloat,
        scaleY: CGFloat
    ) {
        var path = Path()
        switch line.orientation {
        case .vertical:
            let x = (line.position - bounds.minX) * scaleX
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        case .horizontal:
            let y = (line.position - bounds.minY) * scaleY
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(path, with: .color(.white.opacity(0.5)), style: .init(lineWidth: 1, dash: [4, 3]))
    }
}

#Preview("2x2") {
    MonitorPreview(
        bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        zones: ZoneCalculator.zones(
            in: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            lines: [
                GridLine(orientation: .vertical, position: 960),
                GridLine(orientation: .horizontal, position: 540)
            ]
        ),
        lines: [
            GridLine(orientation: .vertical, position: 960),
            GridLine(orientation: .horizontal, position: 540)
        ]
    )
    .padding()
    .frame(width: 480, height: 300)
}
