//
//  OnboardingModelTests.swift
//  ZoneSnapTests
//
//  UI — tests del estado del tutorial de bienvenida.
//

import Foundation
import Testing
@testable import ZoneSnap

@Suite("OnboardingModel")
@MainActor
struct OnboardingModelTests {
    private func freshDefaults() -> UserDefaults {
        let name = "OnboardingTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("la primera vez se debe mostrar")
    func showsOnFirstLaunch() {
        let model = OnboardingModel(defaults: freshDefaults())
        #expect(model.shouldPresentOnLaunch)
    }

    @Test("tras completarlo no se vuelve a mostrar")
    func hiddenAfterComplete() {
        let defaults = freshDefaults()
        OnboardingModel(defaults: defaults).complete()
        #expect(!OnboardingModel(defaults: defaults).shouldPresentOnLaunch)
    }

    @Test("advance no pasa de la última página")
    func advanceStopsAtLast() {
        let model = OnboardingModel(defaults: freshDefaults())
        for _ in 0..<(model.pages.count + 3) { model.advance() }
        #expect(model.currentPage == model.pages.count - 1)
        #expect(model.isLastPage)
    }

    @Test("restart vuelve a la primera página")
    func restartResets() {
        let model = OnboardingModel(defaults: freshDefaults())
        model.advance()
        model.restart()
        #expect(model.currentPage == 0)
    }

    @Test("el guion incluye una página de permiso")
    func hasPermissionPage() {
        let model = OnboardingModel(defaults: freshDefaults())
        #expect(model.pages.contains { $0.kind == .permission })
    }
}
