//
//  OnboardingView.swift
//  ZoneSnap
//
//  UI — tutorial de bienvenida paginado (primera ejecución).
//

import SwiftUI

/// Tutorial de bienvenida: páginas con texto y mini-demos, indicador de progreso
/// y botones Saltar / Siguiente / Empezar. El paso de permiso ofrece concederlo.
struct OnboardingView: View {
    @Bindable var model: OnboardingModel
    var onRequestPermission: () -> Void
    var onFinish: () -> Void

    private var page: OnboardingPage { model.pages[model.currentPage] }

    var body: some View {
        VStack(spacing: 24) {
            OnboardingPageContent(page: page, onRequestPermission: onRequestPermission)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(model.currentPage)
                .transition(.opacity)

            PageIndicator(count: model.pages.count, current: model.currentPage)

            HStack {
                Button("Saltar", action: finish)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Spacer()

                if model.isLastPage {
                    Button("Empezar", action: finish)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Siguiente") {
                        withAnimation { model.advance() }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(28)
        .frame(width: 480, height: 460)
    }

    private func finish() {
        model.complete()
        onFinish()
    }
}

/// Contenido de una página: icono, título, mensaje y, según el tipo, una mini-demo
/// de zonas o el botón para conceder el permiso.
private struct OnboardingPageContent: View {
    let page: OnboardingPage
    var onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.symbol)
                .font(.system(size: 52))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)

            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)

            Text(page.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            switch page.kind {
            case .demo:
                demo
            case .permission:
                Button("Conceder permiso de Accesibilidad", systemImage: "lock.open", action: onRequestPermission)
                    .buttonStyle(.borderedProminent)
            case .info:
                EmptyView()
            }
        }
    }

    private var demo: some View {
        let bounds = CGRect(x: 0, y: 0, width: 480, height: 300)
        let root = ZoneNode.leaf(id: UUID())
        let tree = BSPCalculator.subdivide(root, leaf: root.id, columns: 3, rows: 2)
        return MonitorPreview(bounds: bounds, zones: BSPCalculator.zones(of: tree, in: bounds))
            .frame(height: 150)
    }
}

/// Puntitos de progreso del tutorial.
private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 8, height: 8)
                    .opacity(index == current ? 1 : 0.3)
            }
        }
    }
}

#Preview {
    OnboardingView(model: OnboardingModel(), onRequestPermission: {}, onFinish: {})
}
