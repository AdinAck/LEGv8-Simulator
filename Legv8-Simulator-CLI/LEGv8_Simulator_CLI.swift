//
//  main.swift
//  Legv8-Simulator-CLI
//
//  Created by Adin Ackerman on 10/22/22.
//

import Foundation
import ArgumentParser

@main
struct LEGv8SimulatorCLI: ParsableCommand {
    @Argument(help: "Source file to assemble.")
    var spath: String
    
    @Option(name: .short, help: "Output file name.")
    var opath: String?
    
    @Option(name: .shortAndLong, help: "Execution limit.")
    var exec_limit: Int?
    
    mutating func run() throws {
        let path_out = opath ?? "dump.txt"
        
        let interpreter: Interpreter = Interpreter()
        interpreter.executionLimit = exec_limit ?? 1000

        do {
            let text = try String(contentsOfFile: spath, encoding: .utf8)

            interpreter.assemble(text)

            if interpreter.assembled {

                interpreter.start(text)

                while interpreter.running {
                    interpreter.step(mode: .running)
                }

                try "\(interpreter.cpu)".write(to: URL(fileURLWithPath: path_out), atomically: true, encoding: .utf8)
            } else {
                print("\n -- Errors occurred during assembly --\n")

                var errors: String = ""

                for message in interpreter.log {
                    if message.type == .error {
                        errors += "Line \(message.line): \(message.message)\n\t\(interpreter.lexer.lines[message.line - 1])\n"
                    }
                }

                print(errors)
            }

        } catch let error as NSError {
            print("\(error)")
        }
    }
}
