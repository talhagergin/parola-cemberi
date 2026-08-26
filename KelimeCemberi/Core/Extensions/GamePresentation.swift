import Foundation

extension Int {
    var gameClockText: String {
        String(format: "%02d:%02d", Swift.max(0, self) / 60, Swift.max(0, self) % 60)
    }
}

extension LetterStatus {
    var accessibilityDescription: String {
        switch self {
        case .waiting: "bekliyor"
        case .active: "aktif, soru bekleniyor"
        case .correct: "doğru cevaplandı"
        case .wrong: "yanlış cevaplandı"
        case .passed: "pas geçildi"
        case .unavailable: "soru bulunamadı"
        }
    }
}
