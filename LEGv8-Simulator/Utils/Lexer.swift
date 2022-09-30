//
//  Tokenizer.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import Foundation

class Lexer: ObservableObject {
    var lines: [String]
    @Published var cursor: Int = 0
    
    let specialCharacters: [Character] = ["\t"]
    
    init(text: String) {
        lines = text.components(separatedBy: "\n").map { sub in String(sub)}
    }
    
    func parseNextLine() -> (String, [String]) {
        guard cursor < lines.count else { return ("_end", []) }
        
        if lines[cursor] == "" {
            cursor += 1
            return parseNextLine()
        }
        
        let line: [String] = lines[cursor].map({ char in if specialCharacters.contains(char) { return " " } else { return char }}).split(separator: " ").map { sub in String(sub)}
        
        let instruction: String = line[0].filter({ char in !specialCharacters.contains(char)})
        if instruction.contains("/") { // line is only comment
            cursor += 1
            return parseNextLine()
        } else if instruction.contains(":") {
            let label = String(instruction[..<instruction.firstIndex(of: ":")!])
            cursor += 1
            print("[Tokenizer] Label: \(label)")
            return ("_label", [label])
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
        
        print("[Tokenizer] Instruction: \(instruction), Operands: \(args)")
        
        return (instruction, args)
    }
}
