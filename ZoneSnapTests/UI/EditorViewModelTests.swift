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

    @Test("setColumns reparte el área en columnas iguales")
    func setColumns() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(4)
        #expect(vm.columnCount == 4)
        #expect(vm.previewZones.count == 4)
        #expect(vm.previewZones.allSatisfy { $0.rect.width == 250 })
    }

    @Test("setColumns(1) deja una sola columna")
    func setColumnsToOne() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(3)
        vm.setColumns(1)
        #expect(vm.columnCount == 1)
        #expect(vm.previewZones.count == 1)
    }

    @Test("columnas y filas combinan en una rejilla")
    func columnsAndRowsGrid() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(3)
        vm.setRows(2)
        #expect(vm.columnCount == 3)
        #expect(vm.rowCount == 2)
        #expect(vm.previewZones.count == 6)
    }

    @Test("valores por debajo de 1 se tratan como 1")
    func clampsBelowOne() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(0)
        #expect(vm.columnCount == 1)
        #expect(vm.previewZones.count == 1)
    }
}
