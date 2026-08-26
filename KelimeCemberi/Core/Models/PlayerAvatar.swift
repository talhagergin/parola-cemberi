import Foundation
import SwiftUI

enum PlayerAvatar: String, CaseIterable, Identifiable {
    case robot, astronaut, fox, owl, cat
    var id: String { rawValue }
    var assetName: String {
        switch self {
        case .robot: "AvatarRobot"; case .astronaut: "AvatarAstronaut"; case .fox: "AvatarFox"
        case .owl: "AvatarOwl"; case .cat: "AvatarCat"
        }
    }
    var title: String {
        switch self {
        case .robot: "Robo"; case .astronaut: "Kaşif"; case .fox: "Tilki"; case .owl: "Bilge"; case .cat: "Kozmo"
        }
    }
    var price: Int {
        switch self { case .robot: 0; case .astronaut: 450; case .fox: 600; case .owl: 750; case .cat: 900 }
    }
}

enum CircleTheme: String, CaseIterable, Identifiable {
    case classic, sunset, emerald, galaxy, ice
    var id: String { rawValue }
    var title: String {
        switch self { case .classic: "Klasik Neon"; case .sunset: "Gün Batımı"; case .emerald: "Zümrüt"; case .galaxy: "Galaksi"; case .ice: "Buz Kristali" }
    }
    var price: Int {
        switch self { case .classic: 0; case .sunset: 500; case .emerald: 650; case .galaxy: 850; case .ice: 1_000 }
    }
    var primary: Color {
        switch self { case .classic: GameColors.cyan; case .sunset: Color(red: 1, green: 0.38, blue: 0.12); case .emerald: Color(red: 0.16, green: 0.92, blue: 0.52); case .galaxy: Color(red: 0.73, green: 0.30, blue: 1); case .ice: Color(red: 0.50, green: 0.88, blue: 1) }
    }
    var secondary: Color {
        switch self { case .classic: GameColors.purple; case .sunset: Color(red: 1, green: 0.72, blue: 0.12); case .emerald: Color(red: 0.02, green: 0.42, blue: 0.30); case .galaxy: Color(red: 0.22, green: 0.16, blue: 0.68); case .ice: Color(red: 0.20, green: 0.45, blue: 0.94) }
    }
}
