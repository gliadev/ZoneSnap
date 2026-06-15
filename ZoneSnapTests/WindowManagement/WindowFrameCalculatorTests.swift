//
//  WindowFrameCalculatorTests.swift
//  ZoneSnapTests
//
//  WindowManagement — tests del cálculo del frame destino.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("WindowFrameCalculator")
struct WindowFrameCalculatorTests {
    @Test("boundingRect de una zona es su propio rect")
    func single() {
        let zone = Zone(rect: CGRect(x: 10, y: 20, width: 100, height: 50))
        #expect(WindowFrameCalculator.boundingRect(of: [zone]) == zone.rect)
    }

    @Test("boundingRect une zonas 5+6+8+9 de una 3x3 en el bloque inferior-derecho")
    func unionBottomRightBlock() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let zones = ZoneCalculator.zones(in: bounds, lines: [
            GridLine(orientation: .vertical, position: 640),
            GridLine(orientation: .vertical, position: 1280),
            GridLine(orientation: .horizontal, position: 360),
            GridLine(orientation: .horizontal, position: 720)
        ])
        // En orden de lectura, índices 4,5,7,8 = zonas 5,6,8,9.
        let selection = [zones[4], zones[5], zones[7], zones[8]]
        #expect(WindowFrameCalculator.boundingRect(of: selection) == CGRect(x: 640, y: 360, width: 1280, height: 720))
    }

    @Test("los 4 cuadrantes se unen en el área completa")
    func quadrantsUnion() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let zones = ZoneCalculator.zones(in: bounds, lines: [
            GridLine(orientation: .vertical, position: 500),
            GridLine(orientation: .horizontal, position: 400)
        ])
        #expect(WindowFrameCalculator.boundingRect(of: zones) == bounds)
    }

    @Test("boundingRect de lista vacía es nil")
    func empty() {
        #expect(WindowFrameCalculator.boundingRect(of: []) == nil)
    }

    @Test("globalFrame desplaza por el origen del monitor y conserva el tamaño")
    func globalOffset() {
        let local = CGRect(x: 100, y: 50, width: 800, height: 600)
        let global = WindowFrameCalculator.globalFrame(localRect: local, monitorOrigin: CGPoint(x: 1920, y: 0))
        #expect(global == CGRect(x: 2020, y: 50, width: 800, height: 600))
    }

    @Test("globalFrame con origen (0,0) no cambia el rect")
    func globalZeroOrigin() {
        let local = CGRect(x: 10, y: 10, width: 100, height: 100)
        #expect(WindowFrameCalculator.globalFrame(localRect: local, monitorOrigin: .zero) == local)
    }
}
