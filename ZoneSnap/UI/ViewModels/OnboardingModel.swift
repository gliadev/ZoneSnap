//
//  OnboardingModel.swift
//  ZoneSnap
//
//  UI — estado del tutorial de bienvenida (primera ejecución + navegación).
//

import Foundation
import Observation

/// Estado del tutorial de bienvenida: decide si mostrarlo (primera ejecución,
/// vía `UserDefaults`) y controla la página actual. El `UserDefaults` es
/// inyectable para tests.
@MainActor
@Observable
final class OnboardingModel {
    private let defaults: UserDefaults
    private let seenKey = "hasSeenOnboarding"

    let pages: [OnboardingPage]
    var currentPage = 0

    init(defaults: UserDefaults = .standard, pages: [OnboardingPage] = OnboardingPage.all) {
        self.defaults = defaults
        self.pages = pages
    }

    /// `true` si el tutorial no se ha completado nunca (primera ejecución).
    var shouldPresentOnLaunch: Bool {
        !defaults.bool(forKey: seenKey)
    }

    var isLastPage: Bool {
        currentPage >= pages.count - 1
    }

    /// Avanza a la página siguiente (sin pasarse de la última).
    func advance() {
        if !isLastPage { currentPage += 1 }
    }

    /// Marca el tutorial como visto (no se volverá a mostrar solo).
    func complete() {
        defaults.set(true, forKey: seenKey)
    }

    /// Reinicia el tutorial al principio (para reabrirlo desde el menú).
    func restart() {
        currentPage = 0
    }
}
