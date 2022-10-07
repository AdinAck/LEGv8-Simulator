//
//  Tokenizer.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import Foundation

enum LexerMode {
    case text, long
}

enum LexerError: Error {
    case invalidDataMarker(_ marker: String)
}

class Lexer: ObservableObject {
    var lines: [String]
    @Published var cursor: Int = 0
    
    let specialCharacters: [Character] = ["\t", "\r"]
    
    var mode: LexerMode = .text
    
    init(text: String) {
        lines = text.components(separatedBy: "\n").map { sub in String(sub)}
    }
    
    // TODO: lexer does not differentiate commas and whitespace
    func parseNextLine() throws -> (String, [String]) {
        guard cursor < lines.count else { return ("_end", []) }
        
        // remove special characters and split by whitespace
        let line: [String] = lines[cursor].map({ char in if specialCharacters.contains(char) { return " " } else { return char }}).split(separator: " ").map { sub in String(sub)}
        
        if line.count == 0 { // empty line (or only special characters) disregard nonetheless
            cursor += 1
            return try parseNextLine()
        }
        
        // instruction is first item in line
        let instruction: String = line[0].filter({ char in !specialCharacters.contains(char)})
        
        if instruction.contains("/") { // line is only comment
            cursor += 1
            return try parseNextLine()
        } else if instruction[instruction.startIndex] == "." { // data marker
            let marker = String(instruction[instruction.index(after: instruction.startIndex)...])
            switch marker {
            case "text":
                mode = .text
            case "long":
                mode = .long
            default:
                throw LexerError.invalidDataMarker(marker)
            }
            
            cursor += 1
            return try parseNextLine()
            
        } else if instruction[instruction.index(before: instruction.endIndex)] == ":" { // must be a label
            if mode == .text {
                let label = String(instruction[..<instruction.firstIndex(of: ":")!])
                cursor += 1
                print("[Lexer] Label: \(label)")
                return ("_label", [label])
            } else if mode == .long {
                let label = String(instruction[..<instruction.firstIndex(of: ":")!])
                let args = line[1...].map {sub in String(sub)}
                cursor += 1
                print("[Lexer] \(label): \(args)")
                return ("_long", [label] + args)
            }
        }
        
        var args: [String] = []
        
        for _arg in line[1...].map({ sub in String(sub)}) {
            let arg = _arg.filter({ char in !specialCharacters.contains(char)}) // filter out special characters
            
            
            if arg.contains("/") { // comment
                break
            }
            
            if arg.contains("#") { // literal
                if arg.contains("]") {
                    args.append(String(arg[arg.index(after: arg.firstIndex(of: "#")!)..<arg.firstIndex(of: "]")!]))
                } else if arg.contains(",") {
                    args.append(String(arg[arg.index(after: arg.firstIndex(of: "#")!)..<arg.firstIndex(of: ",")!]))
                } else {
                    args.append(String(arg[arg.index(after: arg.firstIndex(of: "#")!)...]))
                }
            } else { // register
                if arg.contains(",") && arg.contains("[") {
                    args.append(String(arg[arg.index(after: arg.startIndex)..<arg.firstIndex(of: ",")!]))
                } else if arg.contains(",") {
                    args.append(String(arg[..<arg.firstIndex(of: ",")!]))
                } else if arg.contains("[") && arg.contains("]") {
                    args.append(String(arg[arg.index(after: arg.startIndex)..<arg.index(before: arg.endIndex)]))
                } else if arg.contains("[") {
                    args.append(String(arg[arg.index(after: arg.startIndex)...]))
                } else if arg != "]" {
                    args.append(arg)
                }
            }
        }
        
        cursor += 1
        objectWillChange.send()
        
        print("[Lexer] Instruction: \(instruction), Operands: \(args)")
        
        return (instruction, args)
    }
}
