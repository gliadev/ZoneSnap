//
//  OnboardingPage.swift
//  ZoneSnap
//
//  UI — contenido de una página del tutorial de bienvenida.
//

import Foundation

/// Una página del tutorial de bienvenida: texto + símbolo + tipo de contenido.
struct OnboardingPage: Identifiable, Sendable, Hashable {
    /// Animación de demostración que acompaña a una página `.demo`.
    enum DemoKind: Sendable, Hashable {
        /// Una zona se subdivide sola (el resto no se toca).
        case subdivide
        /// Un separador se mueve adelante y atrás (redimensionar).
        case resize
        /// Una ventana salta y se acopla a las zonas (snapping).
        case move
    }

    /// Qué muestra la página, además del texto.
    enum Kind: Sendable, Hashable {
        /// Solo icono + texto.
        case info
        /// Incluye una mini-demo animada de zonas.
        case demo(DemoKind)
        /// Ofrece conceder el permiso de Accesibilidad.
        case permission
    }

    let id: Int
    let title: String
    let message: String
    let symbol: String
    let kind: Kind
}

extension OnboardingPage {
    /// Guion del tutorial (sigue el README).
    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Bienvenido a ZoneSnap",
            message: "Coloca ventanas en zonas a tu medida con un simple atajo de teclado, sin necesidad de arrastrar ni redimensionar con el ratón. En cada monitor.",
            symbol: "rectangle.split.2x2",
            kind: .info
        ),
        OnboardingPage(
            id: 1,
            title: "Crea tus zonas",
            message: "Selecciona una zona y súbela en Columnas o Filas para partirla. Solo se divide esa: el resto del diseño no se toca.",
            symbol: "square.grid.3x3",
            kind: .demo(.subdivide)
        ),
        OnboardingPage(
            id: 2,
            title: "Ajusta a tu gusto",
            message: "Arrastra los separadores para redimensionar las zonas. El botón “Unir” vuelve a juntarlas, y “Limpiar” empieza de cero.",
            symbol: "arrow.left.and.right.square",
            kind: .demo(.resize)
        ),
        OnboardingPage(
            id: 3,
            title: "Mueve ventanas al instante",
            message: "Acopla la ventana activa con el botón, manteniendo Mayús + Control (⇧⌃) y arrastrando, o por teclado: Control + Opción (⌃⌥) y un número (1–9) o las flechas ← / →.",
            symbol: "macwindow.on.rectangle",
            kind: .demo(.move)
        ),
        OnboardingPage(
            id: 4,
            title: "Un permiso para empezar",
            message: "ZoneSnap te deja colocar ventanas solo con el teclado —sin arrastres ni ajustes finos de ratón—, algo pensado para quien no puede hacer esos gestos con precisión. Para lograrlo, macOS pide el permiso de Accesibilidad. Concédelo y listo.",
            symbol: "lock.shield",
            kind: .permission
        )
    ]
}
