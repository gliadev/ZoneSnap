//
//  LaunchAtLoginModelTests.swift
//  ZoneSnapTests
//
//  UI — tests del ajuste "arrancar al iniciar sesión" sobre un manager en memoria.
//

import Foundation
import Testing
@testable import ZoneSnap

@Suite("LaunchAtLoginModel — arranque al inicio")
@MainActor
struct LaunchAtLoginModelTests {
    private struct FakeError: Error {}

    @Test("refleja el estado inicial del sistema")
    func reflectsInitialState() {
        let enabled = LaunchAtLoginModel(manager: InMemoryLoginItemManager(isEnabled: true))
        #expect(enabled.isEnabled)

        let disabled = LaunchAtLoginModel(manager: InMemoryLoginItemManager(isEnabled: false))
        #expect(!disabled.isEnabled)
    }

    @Test("toggle activa y desactiva")
    func toggleFlips() {
        let model = LaunchAtLoginModel(manager: InMemoryLoginItemManager(isEnabled: false))
        model.toggle()
        #expect(model.isEnabled)
        model.toggle()
        #expect(!model.isEnabled)
    }

    @Test("setEnabled fija el estado pedido")
    func setEnabledSets() {
        let model = LaunchAtLoginModel(manager: InMemoryLoginItemManager(isEnabled: false))
        model.setEnabled(true)
        #expect(model.isEnabled)
        #expect(model.lastError == nil)
    }

    @Test("si el sistema rechaza, revierte y guarda el error")
    func failureKeepsStateAndRecordsError() {
        let manager = InMemoryLoginItemManager(isEnabled: false, failure: FakeError())
        let model = LaunchAtLoginModel(manager: manager)
        model.setEnabled(true)
        #expect(!model.isEnabled)           // no cambió: el sistema rechazó
        #expect(model.lastError != nil)     // se registró el motivo
    }

    @Test("una conmutación correcta limpia el error previo")
    func successClearsError() {
        let manager = InMemoryLoginItemManager(isEnabled: false, failure: FakeError())
        let model = LaunchAtLoginModel(manager: manager)
        model.setEnabled(true)
        #expect(model.lastError != nil)

        manager.failure = nil
        model.setEnabled(true)
        #expect(model.isEnabled)
        #expect(model.lastError == nil)
    }

    @Test("refresh re-lee el estado del sistema")
    func refreshReReads() {
        let manager = InMemoryLoginItemManager(isEnabled: false)
        let model = LaunchAtLoginModel(manager: manager)
        try? manager.setEnabled(true)       // cambia el sistema "por fuera"
        #expect(!model.isEnabled)           // el modelo aún no lo sabe
        model.refresh()
        #expect(model.isEnabled)
    }
}
