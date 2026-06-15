//
//  EditorViewModelLineEditingTests.swift
//  ZoneSnapTests
//
//  UI — tests de la edición libre de líneas (arrastrar para redimensionar).
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("EditorViewModel — edición de líneas")
@MainActor
struct EditorViewModelLineEditingTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test("mover una línea cambia el tamaño de las zonas")
    func moveLineResizesZones() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(2) // línea vertical en x=500 → dos columnas de 500
        let lineID = vm.lines[0].id
        vm.moveLine(lineID, to: 240) // múltiplo de 8
        #expect(vm.previewZones[0].rect.width == 240)
        #expect(vm.previewZones[1].rect.width == 760)
    }

    @Test("la posición se ajusta al step de snap")
    func snapsToStep() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(2)
        let lineID = vm.lines[0].id
        vm.moveLine(lineID, to: 303) // step 8 → 304
        #expect(vm.lines[0].position == 304)
    }

    @Test("no se puede arrastrar más allá del margen mínimo")
    func clampsToMargin() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(2)
        let lineID = vm.lines[0].id
        vm.moveLine(lineID, to: -100)
        #expect(vm.lines[0].position == EditorViewModel.lineMinMargin)

        vm.moveLine(lineID, to: 99_999)
        #expect(vm.lines[0].position == bounds.maxX - EditorViewModel.lineMinMargin)
    }

    @Test("mover un id inexistente no hace nada")
    func unknownIDIsNoOp() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(2)
        let before = vm.lines
        vm.moveLine(UUID(), to: 200)
        #expect(vm.lines == before)
    }

    @Test("se pueden crear filas de distinto tamaño moviendo la línea")
    func nonUniformRows() {
        let vm = EditorViewModel(bounds: bounds)
        vm.setRows(2) // línea horizontal en y=400
        vm.moveLine(vm.lines[0].id, to: 240)
        #expect(vm.previewZones[0].rect.height == 240)
        #expect(vm.previewZones[1].rect.height == 560)
    }
}
