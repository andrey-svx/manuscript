import ArgumentParser
import Foundation

struct Manuscript: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A zero-dependency tool to automate UI testing on iOS Simulator.",
        version: "1.0.0",
        subcommands: [Run.self, Init.self, List.self, New.self, Delete.self, Deintegrate.self]
    )
}
