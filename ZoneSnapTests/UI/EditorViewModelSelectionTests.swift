//
//  EditorViewModelSelectionTests.swift
//  ZoneSnapTests
//
//  UI — tests de la selección de zonas del editor.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("EditorViewModel — selección")
@MainActor
struct EditorViewModelSelectionTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    /// VM con una rejilla 2×2 (4 zonas) lista para seleccionar.
    private func makeGridVM() -> EditorViewModel {
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(2)
        vm.setRows(2)
        return vm
    }

    @Test("seleccionar una zona deja solo esa")
    func singleSelection() {
        let vm = makeGridVM()
        let id = vm.previewZones[0].id
        vm.selectZone(id, extending: false)
        #expect(vm.selectedZoneIDs == [id])
        #expect(vm.selectionRect == vm.previewZones[0].rect)
    }

    @Test("Shift suma zonas a la selección")
    func extendingAddsZones() {
        let vm = makeGridVM()
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.selectZone(vm.previewZones[1].id, extending: true)
        #expect(vm.selectedZones.count == 2)
    }

    @Test("la selección múltiple produce su bounding box")
    func selectionRectIsBoundingBox() {
        let vm = makeGridVM()
        // 2x2 de 1000x800 → celdas de 500x400. Zonas 0 y 1 = fila superior completa.
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.selectZone(vm.previewZones[1].id, extending: true)
        #expect(vm.selectionRect == CGRect(x: 0, y: 0, width: 1000, height: 400))
    }

    @Test("Shift sobre una zona ya seleccionada la quita")
    func extendingTogglesOff() {
        let vm = makeGridVM()
        let id = vm.previewZones[0].id
        vm.selectZone(id, extending: true)
        vm.selectZone(id, extending: true)
        #expect(vm.selectedZoneIDs.isEmpty)
    }

    @Test("click sin Shift sobre la única seleccionada la deselecciona")
    func clickSameDeselects() {
        let vm = makeGridVM()
        let id = vm.previewZones[0].id
        vm.selectZone(id, extending: false)
        vm.selectZone(id, extending: false)
        #expect(vm.selectedZoneIDs.isEmpty)
    }

    @Test("cambiar la rejilla limpia la selección")
    func recomputeClearsSelection() {
        let vm = makeGridVM()
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.setColumns(3)
        #expect(vm.selectedZoneIDs.isEmpty)
    }

    @Test("sin selección el rect es nil")
    func emptySelectionRectIsNil() {
        let vm = makeGridVM()
        #expect(vm.selectionRect == nil)
    }
}
