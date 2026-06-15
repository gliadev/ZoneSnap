//
//  EditorViewModelMergeTests.swift
//  ZoneSnapTests
//
//  UI — tests de la fusión de celdas del editor.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("EditorViewModel — fusión de celdas")
@MainActor
struct EditorViewModelMergeTests {
    @Test("fusionar dos zonas seleccionadas las une en una")
    func mergeTwoZones() {
        let vm = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1000, height: 800))
        vm.setColumns(2)
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.selectZone(vm.previewZones[1].id, extending: true)
        vm.mergeSelection()
        #expect(vm.previewZones.count == 1)
        #expect(vm.previewZones[0].rect == CGRect(x: 0, y: 0, width: 1000, height: 800))
    }

    @Test("fusión parcial: une 1+2 arriba y deja 3, 4, 5, 6")
    func partialMerge() {
        let bounds = CGRect(x: 0, y: 0, width: 900, height: 800)
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(3)
        vm.setRows(2) // 6 zonas (1,2,3 arriba; 4,5,6 abajo)
        vm.selectZone(vm.previewZones[0].id, extending: false) // zona 1
        vm.selectZone(vm.previewZones[1].id, extending: true)  // zona 2
        vm.mergeSelection()

        #expect(vm.previewZones.count == 5)
        // La primera en orden de lectura es la zona ancha fusionada 1+2.
        #expect(vm.previewZones[0].rect == CGRect(x: 0, y: 0, width: 600, height: 400))
        // La de abajo-izquierda (4) sigue separada.
        #expect(vm.previewZones.contains { $0.rect == CGRect(x: 0, y: 400, width: 300, height: 400) })
    }

    @Test("separar deshace la fusión")
    func unmerge() {
        let vm = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1000, height: 800))
        vm.setColumns(2)
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.selectZone(vm.previewZones[1].id, extending: true)
        vm.mergeSelection()
        #expect(vm.previewZones.count == 1)

        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.unmergeSelection()
        #expect(vm.previewZones.count == 2)
    }

    @Test("mover una línea conserva la fusión, redimensionándola")
    func moveLineKeepsMerge() {
        let bounds = CGRect(x: 0, y: 0, width: 900, height: 800)
        let vm = EditorViewModel(bounds: bounds)
        vm.setColumns(3)
        vm.setRows(2)
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.selectZone(vm.previewZones[1].id, extending: true)
        vm.mergeSelection()
        #expect(vm.previewZones.count == 5)

        // Mover la línea horizontal hacia arriba: la fusión sigue (5 zonas).
        let horizontal = vm.lines.first { $0.orientation == .horizontal }!
        vm.moveLine(horizontal.id, to: 240)
        #expect(vm.previewZones.count == 5)
        #expect(vm.previewZones[0].rect.height == 240) // la fusión se redimensionó
    }

    @Test("cambiar la rejilla resetea las fusiones")
    func structuralChangeClearsMerges() {
        let vm = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1000, height: 800))
        vm.setColumns(2)
        vm.selectZone(vm.previewZones[0].id, extending: false)
        vm.selectZone(vm.previewZones[1].id, extending: true)
        vm.mergeSelection()
        #expect(vm.previewZones.count == 1)

        vm.setColumns(3)
        #expect(vm.previewZones.count == 3) // fusiones reseteadas
        #expect(vm.merges.isEmpty)
    }
}
