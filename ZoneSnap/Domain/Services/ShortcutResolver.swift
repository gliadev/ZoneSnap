//
//  ShortcutResolver.swift
//  ZoneSnap
//
//  Domain — traduce una tecla + modificadores en una acción de zonas.
//

import Foundation

/// Resuelve qué acción dispara una combinación de teclas. Lógica pura: el atajo
/// base es **Control + Option** + dígito (zona N) o flecha (navegar).
enum ShortcutResolver {
    static func action(key: ShortcutKey, control: Bool, option: Bool) -> ShortcutAction? {
        guard control, option else { return nil }
        switch key {
        case let .digit(number) where (1...9).contains(number):
            return .moveToZone(number)
        case .digit:
            return nil
        case .arrowLeft:
            return .navigate(.previous)
        case .arrowRight:
            return .navigate(.next)
        }
    }
}
