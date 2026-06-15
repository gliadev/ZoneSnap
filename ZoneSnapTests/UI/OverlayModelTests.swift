//
//  OverlayModelTests.swift
//  ZoneSnapTests
//
//  UI — tests del estado del overlay de zonas (incl. span sobre divisorias).
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("OverlayModel")
@MainActor
struct OverlayModelTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    /// Overlay con 2 columnas (línea vertical en x=500).
    private func twoColumnModel() -> OverlayModel {
        let zones = ZoneCalculator.zones(in: bounds, lines: [
            GridLine(orientation: .vertical, position: 500)
        ])
        let model = OverlayModel()
        model.configure(bounds: bounds, zones: zones)
        return model
    }

    @Test("configure deja el overlay sin resaltado")
    func configureClearsHighlight() {
        let model = twoColumnModel()
        #expect(model.zones.count == 2)
        #expect(model.highlightedZoneIDs.isEmpty)
        #expect(model.highlightedRect == nil)
    }

    @Test("en el centro de una zona solo se resalta esa")
    func singleInCenter() {
        let model = twoColumnModel()
        model.highlightZones(at: CGPoint(x: 250, y: 400))
        #expect(model.highlightedZoneIDs.count == 1)
        #expect(model.highlightedRect == CGRect(x: 0, y: 0, width: 500, height: 800))
    }

    @Test("sobre la línea divisoria se resaltan las dos zonas (span)")
    func spanAcrossBoundary() {
        let model = twoColumnModel()
        model.highlightZones(at: CGPoint(x: 500, y: 400))
        #expect(model.highlightedZoneIDs.count == 2)
        #expect(model.highlightedRect == bounds) // unión = área completa
    }

    @Test("sobre la cruz de 4 zonas se resaltan las 4")
    func spanFourZones() {
        let zones = ZoneCalculator.zones(in: bounds, lines: [
            GridLine(orientation: .vertical, position: 500),
            GridLine(orientation: .horizontal, position: 400)
        ])
        let model = OverlayModel()
        model.configure(bounds: bounds, zones: zones)
        model.highlightZones(at: CGPoint(x: 500, y: 400))
        #expect(model.highlightedZoneIDs.count == 4)
        #expect(model.highlightedRect == bounds)
    }

    @Test("un punto fuera del área no resalta nada")
    func noHighlightOutside() {
        let model = twoColumnModel()
        model.highlightZones(at: CGPoint(x: 5000, y: 5000))
        #expect(model.highlightedZoneIDs.isEmpty)
        #expect(model.highlightedRect == nil)
    }
}
