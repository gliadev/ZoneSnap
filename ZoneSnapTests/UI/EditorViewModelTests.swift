//
//  EditorViewModelTests.swift
//  ZoneSnapTests
//
//  UI — tests de la lógica del editor de zonas.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("EditorViewModel")
@MainActor
struct EditorViewModelTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test("arranca con una única zona igual al área")
    func startsWithSingleZone() {
        let vm = EditorViewModel(bounds: bounds)
        #expect(vm.previewZones.count == 1)
        #expect(vm.previewZones.first?.rect == bounds)
    }

    @Test("añadir una línea recalcula la preview")
    func addLineRecomputes() {
        let vm = EditorViewModel(bounds: bounds)
        vm.addLine(.vertical, at: 500)
        #expect(vm.lines.count == 1)
        #expect(vm.previewZones.count == 2)
    }

    @Test("vertical + horizontal producen 4 zonas")
    func twoLinesFourZones() {
        let vm = EditorViewModel(bounds: bounds)
        vm.addLine(.vertical, at: 500)
        vm.addLine(.horizontal, at: 400)
        #expect(vm.previewZones.count == 4)
    }

    @Test("eliminar una línea recalcula")
    func removeLine() {
        let vm = EditorViewModel(bounds: bounds)
        vm.addLine(.vertical, at: 500)
        let id = vm.lines[0].id
        vm.removeLine(id)
        #expect(vm.lines.isEmpty)
        #expect(vm.previewZones.count == 1)
    }

    @Test("clear deja una única zona")
    func clearResets() {
        let vm = EditorViewModel(bounds: bounds)
        vm.addLine(.vertical, at: 300)
        vm.addLine(.horizontal, at: 200)
        vm.clear()
        #expect(vm.lines.isEmpty)
        #expect(vm.previewZones.count == 1)
    }

    @Test("la preview mantiene identidades estables entre lecturas")
    func stablePreviewIdentity() {
        let vm = EditorViewModel(bounds: bounds)
        vm.addLine(.vertical, at: 500)
        #expect(vm.previewZones.map(\.id) == vm.previewZones.map(\.id))
    }
}
