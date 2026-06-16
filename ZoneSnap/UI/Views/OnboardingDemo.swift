//
//  OnboardingDemo.swift
//  ZoneSnap
//
//  UI — mini-demo animada de zonas para el tutorial de bienvenida.
//

import SwiftUI

/// Animación en bucle que ilustra un comportamiento del editor:
/// `.subdivide` (una zona se parte sola sin tocar el resto) o `.resize`
/// (un separador se mueve adelante y atrás). Los árboles se fijan en `init`
/// para que las zonas mantengan identidad y la transición se anime.
struct OnboardingDemo: View {
    private let bounds = CGRect(x: 0, y: 0, width: 480, height: 300)
    private let treeA: ZoneNode
    private let treeB: ZoneNode

    @State private var showB = false

    init(kind: OnboardingPage.DemoKind) {
        switch kind {
        case .subdivide:
            let root = ZoneNode.leaf(id: UUID())
            let grid = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 2)
            let target = BSPCalculator.zones(of: grid, in: bounds).last?.id ?? root.id
            treeA = grid
            treeB = BSPCalculator.setColumns(grid, forLeaf: target, to: 2)
        case .resize:
            let root = ZoneNode.leaf(id: UUID())
            let split = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 1)
            treeA = BSPCalculator.moveBoundary(split, split: split.id, boundary: 0, toFraction: 0.32)
            treeB = BSPCalculator.moveBoundary(split, split: split.id, boundary: 0, toFraction: 0.68)
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

#Preview("subdividir") {
    OnboardingDemo(kind: .subdivide).padding().frame(width: 320)
}

#Preview("redimensionar") {
    OnboardingDemo(kind: .resize).padding().frame(width: 320)
}
