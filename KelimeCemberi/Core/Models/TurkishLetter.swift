import Foundation

enum TurkishLetter: String, Codable, CaseIterable, Identifiable, Sendable {
    case a = "A", b = "B", c = "C", cCedilla = "Ç", d = "D", e = "E"
    case f = "F", g = "G", gBreve = "Ğ", h = "H", iDotless = "I", iDotted = "İ"
    case j = "J", k = "K", l = "L", m = "M", n = "N", o = "O", oUmlaut = "Ö"
    case p = "P", r = "R", s = "S", sCedilla = "Ş", t = "T", u = "U"
    case uUmlaut = "Ü", v = "V", y = "Y", z = "Z"

    var id: String { rawValue }

    static func initialLetter(in text: String) -> TurkishLetter? {
        let uppercase = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased(with: Locale(identifier: "tr_TR"))
        return uppercase.first(where: { $0.isLetter }).flatMap { TurkishLetter(rawValue: String($0)) }
    }
}
