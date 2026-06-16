//
//  MonitorLocatorTests.swift
//  ZoneSnapTests
//
//  WindowManagement — tests de la localización de monitor por punto.
//

import CoreGraphics
import Foundation
import Testing
@testable import ZoneSnap

@Suite("MonitorLocator")
struct MonitorLocatorTests {
    private let mainID = UUID()
    private let secondID = UUID()

    private func screens() -> [(id: Monitor.ID, frame: CGRect)] {
        [
            (mainID, CGRect(x: 0, y: 0, width: 1920, height: 1080)),
            (secondID, CGRect(x: 1920, y: 0, width: 2560, height: 1440))
        ]
    }

    @Test("un punto dentro de un monitor devuelve ese monitor")
    func containingPoint() {
        #expect(MonitorLocator.monitor(containing: CGPoint(x: 100, y: 100), in: screens()) == mainID)
        #expect(MonitorLocator.monitor(containing: CGPoint(x: 2200, y: 200), in: screens()) == secondID)
    }

    @Test("un punto fuera de todos elige el monitor más cercano")
    func nearestWhenOutside() {
        #expect(MonitorLocator.monitor(containing: CGPoint(x: -100, y: 100), in: screens()) == mainID)
        #expect(MonitorLocator.monitor(containing: CGPoint(x: 6000, y: 100), in: screens()) == secondID)
    }

    @Test("sin monitores devuelve nil")
    func emptyMonitors() {
        #expect(MonitorLocator.monitor(containing: .zero, in: []) == nil)
    }
}
