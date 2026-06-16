//
//  EditorViewModelTests.swift
//  ZoneSnapTests
//
//  UI — tests del editor de zonas sobre el árbol de subdivisión (BSP).
//

import CoreGraphics
import Foundation
import Testing
@testable import ZoneSnap

@Suite("EditorViewModel — árbol de zonas")
@MainActor
struct EditorViewModelTests {
    private func makeVM() -> EditorViewModel {
        EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1000, height: 800))
    }

    @Test("arranca con una única zona igual al área")
    func startsWithSingleZone() {
        let vm = makeVM()
        #expect(vm.previewZones.count == 1)
        #expect(vm.boundaries.isEmpty)
    }

    @Test("subdividir la selección en columnas afecta solo a esa zona")
    func subdivideColumnsLocal() {
        let vm = makeVM()
        // Primero parte en 2 columnas la única zona.
        vm.selectZone(vm.previewZones[0].id)
        vm.setColumns(2)
        #expect(vm.previewZones.count == 2)

        // Selecciona la 2ª y mete 3 filas: la 1ª no debe cambiar.
        let first = vm.previewZones[0]
        vm.selectZone(vm.previewZones[1].id)
        vm.setRows(3)
        #expect(vm.previewZones.count == 4) // 1 + 3
        #expect(vm.previewZones.contains { $0.id == first.id }) // la 1ª intacta
    }

    @Test("subdivideSelection crea una rejilla dentro de la zona")
    func subdivideGrid() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        vm.subdivideSelection(columns: 2, rows: 2)
        #expect(vm.previewZones.count == 4)
    }

    @Test("sin selección los steppers no hacen nada")
    func steppersNeedSelection() {
        let vm = makeVM()
        vm.setColumns(3)
        #expect(vm.previewZones.count == 1)
        #expect(!vm.hasSelection)
    }

    @Test("columnCount/rowCount reflejan la franja de la selección")
    func countsReflectSelection() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        vm.setColumns(3)
        vm.selectZone(vm.previewZones[0].id)
        #expect(vm.columnCount == 3)
        #expect(vm.rowCount == 1)
    }

    @Test("unir colapsa la franja de la selección")
    func uniteCollapses() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        vm.setColumns(3)
        #expect(vm.previewZones.count == 3)
        vm.selectZone(vm.previewZones[1].id)
        #expect(vm.canUnite)
        vm.uniteSelection()
        #expect(vm.previewZones.count == 1)
    }

    @Test("clear vuelve a una sola zona")
    func clearResets() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        vm.subdivideSelection(columns: 3, rows: 2)
        vm.clear()
        #expect(vm.previewZones.count == 1)
        #expect(!vm.hasSelection)
    }

    @Test("seleccionar dos veces la misma zona la deselecciona")
    func selectToggles() {
        let vm = makeVM()
        let id = vm.previewZones[0].id
        vm.selectZone(id)
        #expect(vm.selectedZoneID == id)
        vm.selectZone(id)
        #expect(vm.selectedZoneID == nil)
    }

    @Test("la zona seleccionada produce su rect como destino")
    func selectionRect() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        #expect(vm.selectionRect == vm.previewZones[0].rect)
    }

    @Test("subdividir genera fronteras arrastrables")
    func subdivideCreatesBoundaries() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        vm.setColumns(3)
        #expect(vm.boundaries.count == 2) // 3 columnas → 2 fronteras
    }

    @Test("mover una frontera redimensiona las zonas colindantes")
    func moveBoundaryResizes() {
        let vm = makeVM()
        vm.selectZone(vm.previewZones[0].id)
        vm.setColumns(2)
        let boundary = try! #require(vm.boundaries.first)
        vm.moveBoundary(boundary, to: 200) // x=200 de 1000 → 20%
        #expect(abs(vm.previewZones[0].rect.width - 200) < 1)
    }

    @Test("load reconstruye el árbol de una rejilla guardada (compat)")
    func loadReconstructsGrid() {
        let vm = makeVM()
        let zones = [
            Zone(rect: CGRect(x: 0, y: 0, width: 500, height: 800)),
            Zone(rect: CGRect(x: 500, y: 0, width: 500, height: 800))
        ]
        vm.load(zones)
        #expect(vm.previewZones.count == 2)
    }

    @Test("load con lista vacía deja una sola zona")
    func loadEmpty() {
        let vm = makeVM()
        vm.load([])
        #expect(vm.previewZones.count == 1)
    }

    @Test("applyTree restaura un árbol guardado")
    func applyTreeRestores() {
        let vm = makeVM()
        let tree = ZoneNode.split(id: UUID(), axis: .horizontal, ratios: [1, 1],
                                  children: [.leaf(id: UUID()), .leaf(id: UUID())])
        vm.applyTree(tree)
        #expect(vm.previewZones.count == 2)
    }
}
