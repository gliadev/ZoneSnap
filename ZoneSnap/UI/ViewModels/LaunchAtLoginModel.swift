//
//  LaunchAtLoginModel.swift
//  ZoneSnap
//
//  UI — estado del ajuste "arrancar ZoneSnap al iniciar sesión".
//

import Foundation
import Observation

/// Estado observable del ajuste de arranque al inicio de sesión. Envuelve el
/// puerto `LoginItemManaging` para que la UI lo consulte y conmute, reflejando
/// siempre el estado real del sistema y absorbiendo los fallos del registro.
@MainActor
@Observable
final class LaunchAtLoginModel {
    private let manager: any LoginItemManaging

    /// Estado mostrado en la UI; se sincroniza con el sistema al crear y tras
    /// cada conmutación.
    private(set) var isEnabled: Bool

    /// Mensaje de error si la última conmutación falló (p. ej. requiere
    /// aprobación del usuario). `nil` si todo fue bien.
    private(set) var lastError: String?

    init(manager: any LoginItemManaging) {
        self.manager = manager
        isEnabled = manager.isEnabled
    }

    /// Conmuta el ajuste. Si el sistema lo rechaza, revierte el estado mostrado
    /// y guarda el motivo en `lastError`.
    func toggle() {
        setEnabled(!isEnabled)
    }

    func setEnabled(_ enabled: Bool) {
        do {
            try manager.setEnabled(enabled)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        // Refleja el estado real del sistema, haya ido bien o mal.
        isEnabled = manager.isEnabled
    }

    /// Re-lee el estado del sistema (p. ej. al reabrir el menú).
    func refresh() {
        isEnabled = manager.isEnabled
    }
}
