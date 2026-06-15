//
//  CGWindowInfoParserTests.swift
//  ZoneSnapTests
//
//  WindowManagement — tests del parseo de diccionarios de CGWindowList.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("CGWindowInfoParser")
struct CGWindowInfoParserTests {
    /// Construye un diccionario con valores `NSNumber`, como los que entrega
    /// realmente `CGWindowListCopyWindowInfo`.
    private func windowDict(
        id: CGWindowID = 101,
        pid: pid_t = 5_000,
        bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600),
        layer: Int? = 0,
        ownerName: String? = "Safari",
        title: String? = "Página"
    ) -> [String: Any] {
        var dict: [String: Any] = [
            kCGWindowNumber as String: NSNumber(value: id),
            kCGWindowOwnerPID as String: NSNumber(value: pid),
            kCGWindowBounds as String: [
                "X": NSNumber(value: Double(bounds.minX)),
                "Y": NSNumber(value: Double(bounds.minY)),
                "Width": NSNumber(value: Double(bounds.width)),
                "Height": NSNumber(value: Double(bounds.height))
            ] as [String: Any]
        ]
        if let layer { dict[kCGWindowLayer as String] = NSNumber(value: layer) }
        if let ownerName { dict[kCGWindowOwnerName as String] = ownerName }
        if let title { dict[kCGWindowName as String] = title }
        return dict
    }

    @Test("parsea un diccionario válido con todos los campos")
    func parsesValidDictionary() throws {
        let info = try #require(CGWindowInfoParser.parse(windowDict()))
        #expect(info.id == 101)
        #expect(info.ownerPID == 5_000)
        #expect(info.ownerName == "Safari")
        #expect(info.title == "Página")
        #expect(info.layer == 0)
        #expect(info.frame == CGRect(x: 0, y: 0, width: 800, height: 600))
    }

    @Test("devuelve nil si falta el id de ventana")
    func nilWhenMissingID() {
        var dict = windowDict()
        dict.removeValue(forKey: kCGWindowNumber as String)
        #expect(CGWindowInfoParser.parse(dict) == nil)
    }

    @Test("devuelve nil si faltan los bounds")
    func nilWhenMissingBounds() {
        var dict = windowDict()
        dict.removeValue(forKey: kCGWindowBounds as String)
        #expect(CGWindowInfoParser.parse(dict) == nil)
    }

    @Test("la capa por defecto es 0 cuando no viene")
    func defaultsLayerToZero() throws {
        let info = try #require(CGWindowInfoParser.parse(windowDict(layer: nil)))
        #expect(info.layer == 0)
    }

    @Test("la lista descarta las entradas inválidas")
    func listDropsInvalidEntries() {
        var invalid = windowDict(id: 202)
        invalid.removeValue(forKey: kCGWindowNumber as String)
        let parsed = CGWindowInfoParser.parse([windowDict(id: 1), invalid, windowDict(id: 2)])
        #expect(parsed.count == 2)
        #expect(parsed.map(\.id) == [1, 2])
    }
}
