//
//  LocalZoneConfigRepository.swift
//  ZoneSnap
//
//  Persistence — implementación local (JSON en disco) del repositorio.
//

import Foundation

/// Implementación local de `ZoneConfigRepository`: persiste `ZoneConfig` como
/// JSON en disco.
///
/// Es un `actor` para serializar los accesos al fichero y ser `Sendable` bajo
/// concurrencia estricta de Swift 6. El directorio base es inyectable, lo que
/// permite testear contra un directorio temporal sin tocar el del usuario.
actor LocalZoneConfigRepository: ZoneConfigRepository {
    private let directory: URL

    /// Nombre del fichero de configuración en disco.
    private static let fileName = "zones.json"

    /// Directorio por defecto: `~/Library/Application Support/ZoneSnap/`.
    static var defaultDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "ZoneSnap", directoryHint: .isDirectory)
    }

    init(directory: URL = LocalZoneConfigRepository.defaultDirectory) {
        self.directory = directory
    }

    private var fileURL: URL {
        directory.appending(path: Self.fileName, directoryHint: .notDirectory)
    }

    func load() async throws -> ZoneConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return ZoneConfig()
        }
        let data = try Data(contentsOf: fileURL)
        let config = try JSONDecoder().decode(ZoneConfig.self, from: data)
        guard config.version <= ZoneConfig.currentVersion else {
            throw ZoneConfigRepositoryError.unsupportedVersion(
                found: config.version,
                supported: ZoneConfig.currentVersion
            )
        }
        return config
    }

    func save(_ config: ZoneConfig) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: fileURL, options: .atomic)
    }
}
