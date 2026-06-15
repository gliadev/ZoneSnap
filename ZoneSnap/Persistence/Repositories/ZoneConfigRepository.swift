//
//  ZoneConfigRepository.swift
//  ZoneSnap
//
//  Persistence — puerto (abstracción) para guardar/cargar la configuración.
//

import Foundation

/// Puerto de persistencia para la configuración de zonas.
///
/// Abstrae el almacenamiento de `ZoneConfig` para poder cambiar la
/// implementación (local en disco hoy, CloudKit en el futuro) sin tocar las
/// capas superiores. Ver `LocalZoneConfigRepository`.
protocol ZoneConfigRepository: Sendable {
    /// Carga la configuración persistida. Si no existe en disco, devuelve una
    /// `ZoneConfig` por defecto.
    func load() async throws -> ZoneConfig

    /// Guarda la configuración, creando el directorio destino si hace falta.
    func save(_ config: ZoneConfig) async throws
}

/// Errores de la capa de persistencia de la configuración.
enum ZoneConfigRepositoryError: Error, Equatable {
    /// El fichero en disco usa una versión de formato más nueva que la que esta
    /// build entiende. No se intenta leer, para no corromper datos.
    case unsupportedVersion(found: Int, supported: Int)
}
