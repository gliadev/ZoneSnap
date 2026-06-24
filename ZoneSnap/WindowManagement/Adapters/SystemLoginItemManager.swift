//
//  SystemLoginItemManager.swift
//  ZoneSnap
//
//  WindowManagement — adapter del ítem de inicio de sesión (arranque al login).
//

import ServiceManagement

/// Adapter: registra ZoneSnap como ítem de inicio de sesión vía `SMAppService`
/// (macOS 13+), la API moderna que sustituye a los `LaunchAgent` manuales.
///
/// Verificación manual: solo funciona con la app firmada y ejecutándose desde
/// una ubicación estable (idealmente `/Applications`). En modo Debug desde Xcode
/// el sistema puede ignorar el registro.
@MainActor
struct SystemLoginItemManager: LoginItemManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
