//
//  InMemoryLoginItemManager.swift
//  ZoneSnap
//
//  WindowManagement — ítem de inicio en memoria (previews y tests).
//

import Foundation

/// Implementación de `LoginItemManaging` en memoria, sin tocar el sistema. Útil
/// para previews de SwiftUI y para tests del modelo de "arrancar al iniciar".
///
/// `failure`, si se asigna, hace que `setEnabled` lance ese error (simula el
/// rechazo del sistema).
@MainActor
final class InMemoryLoginItemManager: LoginItemManaging {
    private(set) var isEnabled: Bool
    var failure: (any Error)?

    init(isEnabled: Bool = false, failure: (any Error)? = nil) {
        self.isEnabled = isEnabled
        self.failure = failure
    }

    func setEnabled(_ enabled: Bool) throws {
        if let failure { throw failure }
        isEnabled = enabled
    }
}
