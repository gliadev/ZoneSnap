//
//  CGWindowListProvider.swift
//  ZoneSnap
//
//  WindowManagement — adapter de ventanas sobre CGWindowList.
//

import CoreGraphics

/// Adapter: lista las ventanas en pantalla vía `CGWindowListCopyWindowInfo`.
///
/// El parseo de los diccionarios se delega en `CGWindowInfoParser` (testeable
/// aparte). La geometría está disponible sin permisos; los títulos pueden venir
/// vacíos sin permiso de grabación de pantalla. Verificación manual.
struct CGWindowListProvider: WindowProviding {
    func currentWindows() -> [WindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
        else {
            return []
        }
        return CGWindowInfoParser.parse(raw)
    }
}
