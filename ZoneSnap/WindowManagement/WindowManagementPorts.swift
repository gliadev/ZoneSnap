//
//  WindowManagementPorts.swift
//  ZoneSnap
//
//  WindowManagement — puertos (protocolos) de las capacidades de sistema.
//

import CoreGraphics

/// Puerto: fuente de los monitores actualmente conectados.
///
/// `async` porque la implementación real lee `NSScreen`, aislado en el main actor.
protocol MonitorProviding: Sendable {
    func currentMonitors() async -> [Monitor]
}

/// Puerto: fuente de las ventanas actualmente en pantalla.
protocol WindowProviding: Sendable {
    func currentWindows() -> [WindowInfo]
}

/// Puerto: estado y solicitud del permiso de Accesibilidad del sistema.
protocol AccessibilityAuthorizing: Sendable {
    /// `true` si la app ya tiene permiso de Accesibilidad.
    var isTrusted: Bool { get }

    /// Solicita el permiso (puede mostrar el diálogo del sistema). Devuelve el
    /// estado de confianza tras la llamada.
    @discardableResult
    func requestAccess() -> Bool
}

/// Puerto: alta/baja de ZoneSnap como ítem de inicio de sesión (arrancar al
/// encender el equipo). Aislado al main actor: solo se usa desde la UI.
@MainActor
protocol LoginItemManaging {
    /// `true` si la app está registrada para arrancar al iniciar sesión.
    var isEnabled: Bool { get }

    /// Registra (o da de baja) la app como ítem de inicio. Puede lanzar si el
    /// sistema rechaza el cambio (p. ej. requiere aprobación del usuario).
    func setEnabled(_ enabled: Bool) throws
}
