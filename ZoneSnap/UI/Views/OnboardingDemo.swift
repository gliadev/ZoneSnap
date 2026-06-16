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

/// Anima un cambio en el árbol de zonas: `.subdivide` (una zona se parte sola sin
/// tocar el resto) o `.resize` (un separador se mueve). Los árboles se fijan en
/// `init` para que las zonas conserven identidad y la transición se anime.
private struct ZoneTreeDemo: View {
    private let bounds = CGRect(x: 0, y: 0, width: 480, height: 300)
    private let treeA: ZoneNode
    private let treeB: ZoneNode

    @State private var showB = false

    init(kind: OnboardingPage.DemoKind) {
        switch kind {
        case .resize:
            let root = ZoneNode.leaf(id: UUID())
            let split = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 1)
            treeA = BSPCalculator.moveBoundary(split, split: split.id, boundary: 0, toFraction: 0.32)
            treeB = BSPCalculator.moveBoundary(split, split: split.id, boundary: 0, toFraction: 0.68)
        case .subdivide, .move:
            let root = ZoneNode.leaf(id: UUID())
            let grid = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 2)
            let target = BSPCalculator.zones(of: grid, in: bounds).last?.id ?? root.id
            treeA = grid
            treeB = BSPCalculator.setColumns(grid, forLeaf: target, to: 2)
        }
    }

    var body: some View {
        MonitorPreview(bounds: bounds, zones: BSPCalculator.zones(of: showB ? treeB : treeA, in: bounds))
            .frame(height: 150)
            .animation(.easeInOut(duration: 0.6), value: showB)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.3))
                    showB.toggle()
                }
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
            let target = zones.isEmpty ? .zero : zones[index].rect

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
                if !zones.isEmpty { index = (index + 1) % zones.count }
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

#Preview("subdividir") {
    OnboardingDemo(kind: .subdivide).padding().frame(width: 320)
}

#Preview("redimensionar") {
    OnboardingDemo(kind: .resize).padding().frame(width: 320)
}

#Preview("mover") {
    OnboardingDemo(kind: .move).padding().frame(width: 320)
}
