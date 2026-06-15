//
//  WindowSnapper+Preview.swift
//  ZoneSnap
//
//  WindowManagement — instancia de WindowSnapper para previews de SwiftUI.
//

import Foundation

extension WindowSnapper {
    /// Snapper para previews: usa los adapters reales, pero no se invocan en preview.
    static var preview: WindowSnapper {
        WindowSnapper(mover: AXWindowMover(), authorizer: SystemAccessibilityAuthorizer())
    }
}
