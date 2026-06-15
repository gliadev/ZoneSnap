//
//  CGWindowInfoParser.swift
//  ZoneSnap
//
//  WindowManagement — parseo de los diccionarios de CGWindowList.
//

import CoreGraphics
import Foundation

/// Convierte los diccionarios crudos de `CGWindowListCopyWindowInfo` en
/// `WindowInfo`. Aislado como función pura para poder testearlo sin el window
/// server (alimentándolo con diccionarios de ejemplo).
enum CGWindowInfoParser {
    /// Parsea un único diccionario de ventana. Devuelve `nil` si faltan campos
    /// obligatorios (`id`, `pid` o `bounds`).
    static func parse(_ info: [String: Any]) -> WindowInfo? {
        guard
            let id = info[kCGWindowNumber as String] as? CGWindowID,
            let pid = info[kCGWindowOwnerPID as String] as? pid_t,
            let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
            let frame = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
        else { return nil }

        let layer = info[kCGWindowLayer as String] as? Int ?? 0
        let ownerName = info[kCGWindowOwnerName as String] as? String
        let title = info[kCGWindowName as String] as? String

        return WindowInfo(
            id: id,
            ownerName: ownerName,
            title: title,
            ownerPID: pid,
            frame: frame,
            layer: layer
        )
    }

    /// Parsea la lista completa, descartando las entradas inválidas.
    static func parse(_ infos: [[String: Any]]) -> [WindowInfo] {
        infos.compactMap(parse)
    }
}
