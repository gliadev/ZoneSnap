//
//  OnboardingDemo.swift
//  ZoneSnap
//
//  UI — mini-demos animadas de zonas para el tutorial de bienvenida.
//

import SwiftUI

/// Selecciona la animación de demostración según el tipo de página.
struct OnboardingDemo: View {
    let kind: OnboardingPage.DemoKind

    var body: some View {
        switch kind {
        case .subdivide, .resize:
            ZoneTreeDemo(kind: kind)
        case .move:
            WindowSnapDemo()
        }
    }
}

/// Recorre en bucle una secuencia de árboles de zonas:
/// `.subdivide` muestra cómo se *crean* (1 → 2 columnas → 2×2 → subdividir una);
/// `.resize` mueve el separador de columnas y luego el de filas (mismos ids, así
/// el redimensionado se anima suave).
private struct ZoneTreeDemo: View {
    private let bounds = CGRect(x: 0, y: 0, width: 480, height: 300)
    private let frames: [ZoneNode]

    @State private var index = 0

    init(kind: OnboardingPage.DemoKind) {
        frames = ZoneTreeDemo.frames(for: kind, in: bounds)
    }

    var body: some View {
        let tree = frames[index % frames.count]
        MonitorPreview(bounds: bounds, zones: BSPCalculator.zones(of: tree, in: bounds))
            .frame(height: 150)
            .animation(.easeInOut(duration: 0.55), value: index)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.2))
                    index += 1
                }
            }
    }

    private static func frames(for kind: OnboardingPage.DemoKind, in bounds: CGRect) -> [ZoneNode] {
        switch kind {
        case .subdivide:
            let root = ZoneNode.leaf(id: UUID())
            let columns = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 1)
            let grid = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 2)
            let target = BSPCalculator.zones(of: grid, in: bounds).last?.id ?? root.id
            let nested = BSPCalculator.setColumns(grid, forLeaf: target, to: 2)
            return [root, columns, grid, nested]

        case .resize:
            let topID = UUID(), bottomID = UUID(), rootID = UUID()
            let top = ZoneNode.split(id: topID, axis: .vertical, ratios: [1, 1],
                                     children: [.leaf(id: UUID()), .leaf(id: UUID())])
            let bottom = ZoneNode.split(id: bottomID, axis: .vertical, ratios: [1, 1],
                                        children: [.leaf(id: UUID()), .leaf(id: UUID())])
            let base = ZoneNode.split(id: rootID, axis: .horizontal, ratios: [1, 1], children: [top, bottom])
            // Columnas desiguales (mueve el separador vertical de ambas filas).
            let wideColumns = BSPCalculator.moveBoundary(
                BSPCalculator.moveBoundary(base, split: topID, boundary: 0, toFraction: 0.66),
                split: bottomID, boundary: 0, toFraction: 0.66
            )
            // Filas desiguales (mueve el separador horizontal).
            let tallRows = BSPCalculator.moveBoundary(base, split: rootID, boundary: 0, toFraction: 0.66)
            return [base, wideColumns, base, tallRows]

        case .move:
            return [.leaf(id: UUID())]
        }
    }
}

/// Una "ventana" que salta y se acopla a cada zona en bucle (snapping).
private struct WindowSnapDemo: View {
    private let bounds = CGRect(x: 0, y: 0, width: 480, height: 280)
    private let zones: [Zone]

    @State private var index = 0

    init() {
        let root = ZoneNode.leaf(id: UUID())
        let tree = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 2)
        zones = BSPCalculator.zones(of: tree, in: bounds)
    }

    var body: some View {
        GeometryReader { proxy in
            let scaleX = proxy.size.width / bounds.width
            let scaleY = proxy.size.height / bounds.height
            let target = zones.isEmpty ? .zero : zones[index % max(zones.count, 1)].rect

            ZStack(alignment: .topLeading) {
                ForEach(zones) { zone in
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: zone.rect.width * scaleX, height: zone.rect.height * scaleY)
                        .offset(x: zone.rect.minX * scaleX, y: zone.rect.minY * scaleY)
                }

                window
                    .frame(width: target.width * scaleX - 10, height: target.height * scaleY - 10)
                    .offset(x: target.minX * scaleX + 5, y: target.minY * scaleY + 5)
            }
            .animation(.easeInOut(duration: 0.55), value: index)
        }
        .frame(height: 150)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.1))
                index += 1
            }
        }
    }

    private var window: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.tint.opacity(0.85))
            .overlay(alignment: .topLeading) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(.white.opacity(0.85)).frame(width: 4, height: 4)
                    }
                }
                .padding(6)
            }
    }
}

#Preview("crear zonas") {
    OnboardingDemo(kind: .subdivide).padding().frame(width: 320)
}

#Preview("redimensionar") {
    OnboardingDemo(kind: .resize).padding().frame(width: 320)
}

#Preview("mover") {
    OnboardingDemo(kind: .move).padding().frame(width: 320)
}
