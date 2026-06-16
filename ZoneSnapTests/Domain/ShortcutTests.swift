//
//  ShortcutTests.swift
//  ZoneSnapTests
//
//  Domain — tests del parseo de atajos y la navegación entre zonas.
//

import CoreGraphics
import Foundation
import Testing
@testable import ZoneSnap

@Suite("ShortcutResolver — tecla → acción")
struct ShortcutResolverTests {
    @Test("sin Control+Option no hay acción")
    func requiresModifiers() {
        #expect(ShortcutResolver.action(key: .digit(1), control: false, option: false) == nil)
        #expect(ShortcutResolver.action(key: .digit(1), control: true, option: false) == nil)
        #expect(ShortcutResolver.action(key: .arrowRight, control: false, option: true) == nil)
    }

    @Test("Control+Option + dígito mueve a esa zona")
    func digitMovesToZone() {
        #expect(ShortcutResolver.action(key: .digit(1), control: true, option: true) == .moveToZone(1))
        #expect(ShortcutResolver.action(key: .digit(9), control: true, option: true) == .moveToZone(9))
    }

    @Test("dígitos fuera de 1…9 no producen acción")
    func digitOutOfRange() {
        #expect(ShortcutResolver.action(key: .digit(0), control: true, option: true) == nil)
        #expect(ShortcutResolver.action(key: .digit(10), control: true, option: true) == nil)
    }

    @Test("flechas navegan anterior/siguiente")
    func arrowsNavigate() {
        #expect(ShortcutResolver.action(key: .arrowLeft, control: true, option: true) == .navigate(.previous))
        #expect(ShortcutResolver.action(key: .arrowRight, control: true, option: true) == .navigate(.next))
    }
}

@Suite("ZoneNavigator — zona destino")
struct ZoneNavigatorTests {
    private func zones() -> [Zone] {
        TestZones.grid(CGRect(x: 0, y: 0, width: 900, height: 100), columns: 3, rows: 1)
    }

    @Test("moveToZone devuelve la zona por número (1-based)")
    func moveToZoneByNumber() {
        let z = zones()
        #expect(ZoneNavigator.destination(for: .moveToZone(1), in: z, current: nil)?.id == z[0].id)
        #expect(ZoneNavigator.destination(for: .moveToZone(3), in: z, current: nil)?.id == z[2].id)
    }

    @Test("moveToZone fuera de rango devuelve nil")
    func moveToZoneOutOfRange() {
        #expect(ZoneNavigator.destination(for: .moveToZone(4), in: zones(), current: nil) == nil)
    }

    @Test("navigate siguiente avanza una zona")
    func navigateNext() {
        let z = zones()
        let dest = ZoneNavigator.destination(for: .navigate(.next), in: z, current: z[0].id)
        #expect(dest?.id == z[1].id)
    }

    @Test("navigate anterior con wrap-around va a la última")
    func navigatePreviousWraps() {
        let z = zones()
        let dest = ZoneNavigator.destination(for: .navigate(.previous), in: z, current: z[0].id)
        #expect(dest?.id == z[2].id)
    }

    @Test("navigate sin zona actual empieza por la primera")
    func navigateWithoutCurrent() {
        let z = zones()
        #expect(ZoneNavigator.destination(for: .navigate(.next), in: z, current: nil)?.id == z[0].id)
    }
}
