//
//  OnboardingPage.swift
//  ZoneSnap
//
//  UI — contenido de una página del tutorial de bienvenida.
//

import Foundation

/// Una página del tutorial de bienvenida: texto + símbolo + tipo de contenido.
struct OnboardingPage: Identifiable, Sendable, Hashable {
    /// Qué muestra la página, además del texto.
    enum Kind: Sendable, Hashable {
        /// Solo icono + texto.
        case info
        /// Incluye una mini-demo visual de zonas.
        case demo
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
            message: "Crea zonas a tu medida en cada monitor y acopla las ventanas a ellas con el ratón o el teclado.",
            symbol: "rectangle.split.2x2",
            kind: .info
        ),
        OnboardingPage(
            id: 1,
            title: "Crea tus zonas",
            message: "Selecciona una zona y súbela en Columnas o Filas para partirla. Solo se divide esa: el resto del diseño no se toca.",
            symbol: "square.grid.3x3",
            kind: .demo
        ),
        OnboardingPage(
            id: 2,
            title: "Ajusta a tu gusto",
            message: "Arrastra los separadores para redimensionar las zonas. El botón “Unir” vuelve a juntarlas, y “Limpiar” empieza de cero.",
            symbol: "arrow.left.and.right.square",
            kind: .demo
        ),
        OnboardingPage(
            id: 3,
            title: "Mueve ventanas al instante",
            message: "Usa el botón, mantén ⇧⌃ y arrastra una ventana, o con el teclado: ⌃⌥1…9 para ir a una zona y ⌃⌥←/→ para navegar.",
            symbol: "macwindow.on.rectangle",
            kind: .info
        ),
        OnboardingPage(
            id: 4,
            title: "Un permiso para empezar",
            message: "Para mover ventanas de otras apps, macOS pide permiso de Accesibilidad. Concédelo y ya estará todo listo.",
            symbol: "lock.shield",
            kind: .permission
        )
    ]
}
