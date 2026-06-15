//
//  DragOverlayController+Preview.swift
//  ZoneSnap
//
//  WindowManagement — instancia para previews de SwiftUI.
//

import Foundation

extension DragOverlayController {
    /// Controller para previews: no se arranca realmente en el snapshot.
    static var preview: DragOverlayController {
        DragOverlayController(app: .preview, mover: AXWindowMover())
    }
}
