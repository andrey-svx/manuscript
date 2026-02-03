import Foundation

enum ANSI {
    static let reset = "\u{001B}[0m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let bold = "\u{001B}[1m"
    static let gray = "\u{001B}[90m"
}

func log(_ message: String, color: String = ANSI.reset) {
    print("\(color)\(message)\(ANSI.reset)")
}

func logError(_ message: String) {
    print("\(ANSI.red)Error: \(message)\(ANSI.reset)")
    exit(1)
}
