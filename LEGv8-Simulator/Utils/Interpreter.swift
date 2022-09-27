//
//  Interpreter.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import Foundation

enum LineType {
    case normal, label, error
}

struct LogEntry: Identifiable, Equatable {
    let id: Int
    let line: Int
    let message: String
    let type: LineType
}

class Interpreter: ObservableObject {
    @Published var tokenizer: Tokenizer!
    @Published var cpu: CPUModel = CPUModel()
    
    @Published var running: Bool = false
    @Published var programCounter: Int = 0
    
    @Published var lastTouchedRegister: String?
    @Published var lastTouchedMemory: Int64?
    
    @Published var log: [LogEntry] = []
    
    var labelMap: [String: Int] = [:]
    
    func start(_ text: String) {
        self.tokenizer = Tokenizer(text: text)
        self.cpu = CPUModel()
        cpu.updateStackPointer()
        
        programCounter = 0
        log = []
    }
    
    private func literalToInt64(_ literal: String) -> Int64 {
        if literal.contains("x") {
            return Int64(String(literal[literal.index(after: literal.firstIndex(of: "x")!)...]), radix: 16)!
        } else {
            return Int64(literal)!
        }
    }
    
    private func writeToLog(_ message: String, type: LineType = .normal) {
        print(message)
        log.append(LogEntry(id: programCounter, line: tokenizer.cursor, message: message, type: type))
        programCounter += 1
        objectWillChange.send()
    }
    
    private func isValidLabel(_ label: String) throws {
        guard labelMap.keys.contains(label) else { throw CPUError.invalidLabel }
    }
    
    func b(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        tokenizer.cursor = labelMap[label]!
    }
    
    func step() {
        if programCounter > 1000 {
            writeToLog("[InstructionLimitExceeded] The maximum execution count has been exceeded, this could be due to infinite recursion. You can change this limit in Preferences.", type: .error)
            running = false
            return
        }
        
        let (instruction, arguments) = tokenizer.parseNextLine()
        
        if instruction == "_end" {
            writeToLog("")
        } else if instruction == "_label" {
            writeToLog(tokenizer.lines[tokenizer.cursor - 1], type: .label)
        } else {
            writeToLog(tokenizer.lines[tokenizer.cursor - 1])
        }
        
        do {
            switch instruction {
            case "add":
                try cpu.add(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "sub":
                try cpu.sub(arguments[0], arguments[1], arguments[3])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "addi":
                try cpu.addi(arguments[0], arguments[1], literalToInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "subi":
                try cpu.subi(arguments[0], arguments[1], literalToInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "ldur":
                var offset: Int64 = 0
                if arguments.count > 2 {
                    offset = Int64(arguments[2])!
                }
                
                try cpu.ldur(arguments[0], arguments[1], offset)
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "stur":
                var offset: Int64 = 0
                if arguments.count > 2 {
                    if let _offset = Int64(arguments[2]) {
                        offset = _offset
                    }
                }
                
                try cpu.stur(arguments[0], arguments[1], offset)
                lastTouchedRegister = nil
                lastTouchedMemory = cpu.registers[arguments[1]]! + offset
            case "movz":
                try cpu.movz(arguments[0], Int64(arguments[1])!, arguments[2], Int64(arguments[3])!)
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "mov":
                try cpu.mov(arguments[0], arguments[1])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "and":
                try cpu.and(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "andi":
                try cpu.andi(arguments[0], arguments[1], literalToInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "orr":
                try cpu.orr(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "orri":
                try cpu.orri(arguments[0], arguments[1], literalToInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "eor":
                try cpu.eor(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "eori":
                try cpu.eori(arguments[0], arguments[1], literalToInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "b":
                try b(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "_label":
                labelMap[arguments[0]] = tokenizer.cursor - 1
                step()
            case "_end":
                running = false
                tokenizer.cursor = 0
            default:
                writeToLog("[UnknownInstruction] Line \(tokenizer.cursor)", type: .error)
                running = false
            }
        } catch CPUError.invalidRegister {
            writeToLog("[InvalidRegister] Line \(tokenizer.cursor)", type: .error)
            running = false
        } catch CPUError.invalidLiteral {
            writeToLog("[InvalidLiteral] Line \(tokenizer.cursor): Literal values may range between -4095 and 4095", type: .error)
            running = false
        } catch CPUError.readOnlyRegister {
            writeToLog("[ReadOnlyRegister] Line \(tokenizer.cursor)", type: .error)
            running = false
        } catch CPUError.invalidMemoryAccess {
            writeToLog("[InvalidMemoryAccess] Line \(tokenizer.cursor): Memory accessed outside stack bounds.", type: .error)
            running = false
        } catch CPUError.stackPointerMisaligned {
            writeToLog("[StackPointerMisaligned] Line \(tokenizer.cursor): The stack pointer must be quadword aligned.", type: .error)
            running = false
        } catch CPUError.invalidLabel {
            writeToLog("[InvalidLabel] Line \(tokenizer.cursor): The referenced label does not exist.", type: .error)
            running = false
        } catch {
            writeToLog("Unknown error.", type: .error)
            running = false
        }
        
        cpu.updateStackPointer()
        objectWillChange.send()
    }
}
