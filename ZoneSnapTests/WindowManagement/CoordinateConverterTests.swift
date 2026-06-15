//
//  CoordinateConverterTests.swift
//  ZoneSnapTests
//
//  WindowManagement — tests de la conversión de coordenadas.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("CoordinateConverter")
struct CoordinateConverterTests {
    private let converter = CoordinateConverter(primaryHeight: 1080)

    @Test("toTopLeft refleja la y respecto a la altura del display")
    func toTopLeft() {
        // Rect AppKit (bottom-left): abajo del todo, alto 200 → arriba en top-left.
        let appKit = CGRect(x: 100, y: 0, width: 300, height: 200)
        let topLeft = converter.toTopLeft(appKit)
        #expect(topLeft == CGRect(x: 100, y: 880, width: 300, height: 200))
    }

    @Test("la conversión es involutiva (ida y vuelta = original)")
    func involutive() {
        let original = CGRect(x: 42, y: 137, width: 640, height: 480)
        #expect(converter.toBottomLeft(converter.toTopLeft(original)) == original)
    }

    @Test("preserva x, ancho y alto")
    func preservesXAndSize() {
        let rect = CGRect(x: 50, y: 300, width: 400, height: 250)
        let converted = converter.toTopLeft(rect)
        #expect(converted.minX == rect.minX)
        #expect(converted.size == rect.size)
    }

    @Test("una ventana a pantalla completa se mantiene en (0,0)")
    func fullScreenStaysAtOrigin() {
        let full = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #expect(converter.toTopLeft(full) == full)
    }
}
