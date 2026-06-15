//
//  OverlayModelTests.swift
//  ZoneSnapTests
//
//  UI — tests del estado del overlay de zonas.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("OverlayModel")
@MainActor
struct OverlayModelTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    private func makeModel() -> OverlayModel {
        let zones = ZoneCalculator.zones(in: bounds, lines: [
            GridLine(orientation: .vertical, position: 500)
        ])
        let model = OverlayModel()
        model.configure(bounds: bounds, zones: zones)
        return model
    }

    @Test("configure deja el overlay sin resaltado")
    func configureClearsHighlight() {
        let model = makeModel()
        #expect(model.zones.count == 2)
        #expect(model.highlightedZoneID == nil)
    }

    @Test("highlightZone resalta la zona bajo el punto")
    func highlightsZoneUnderPoint() {
        let model = makeModel()
        model.highlightZone(at: CGPoint(x: 250, y: 400)) // mitad izquierda
        #expect(model.highlightedZoneID == model.zones[0].id)

        model.highlightZone(at: CGPoint(x: 750, y: 400)) // mitad derecha
        #expect(model.highlightedZoneID == model.zones[1].id)
    }

    @Test("un punto fuera del área no resalta nada")
    func noHighlightOutside() {
        let model = makeModel()
        model.highlightZone(at: CGPoint(x: 5000, y: 5000))
        #expect(model.highlightedZoneID == nil)
    }
}
