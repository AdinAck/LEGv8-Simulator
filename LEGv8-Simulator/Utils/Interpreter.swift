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
    
    private func literalToInt64(_ literal: String) throws -> Int64 {
        if literal.contains("x") {
            if let result = Int64(String(literal[literal.index(after: literal.firstIndex(of: "x")!)...]), radix: 16) {
                return result
            }
        } else {
            if let result = Int64(literal) {
                return result
            }
        }
        
        throw CPUError.invalidLiteral(literal)
    }
    
    private func writeToLog(_ message: String, type: LineType = .normal) {
        print(message)
        log.append(LogEntry(id: programCounter, line: tokenizer.cursor, message: message, type: type))
        programCounter += 1
        objectWillChange.send()
    }
    
    private func isValidLabel(_ label: String) throws {
        guard labelMap.keys.contains(label) else { throw CPUError.invalidLabel(label) }
    }
    
    func b(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        tokenizer.cursor = labelMap[label]!
    }
    
    func b_eq() throws {
        
    }
    
    func b_ne() throws {
        
    }
    
    func b_hs() throws {
        
    }
    
    func b_lo() throws {
        
    }
    
    func b_hi() throws {
        
    }
    
    func b_ls() throws {
        
    }
    
    func b_ge() throws {
        
    }
    
    func b_lt() throws {
        
    }
    
    func b_gt() throws {
        
    }
    
    func b_le() throws {
        
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
                writeToLog("[UnknownInstruction] Unkown instruction \"\(instruction)\".", type: .error)
                running = false
            }
        } catch CPUError.invalidInstruction(let instruction) {
            writeToLog("[InvalidInstruction] Invalid instruction \"\(instruction)\".", type: .error)
            running = false
        } catch CPUError.invalidRegister(let register) {
            writeToLog("[InvalidRegister] Invalid register \"\(register)\".", type: .error)
            running = false
        } catch CPUError.invalidLiteral(let literal) {
            writeToLog("[InvalidLiteral] Invalid literal value \"\(literal)\". Literal values may range between -4095 and 4095.", type: .error)
            running = false
        } catch CPUError.readOnlyRegister(let register) {
            writeToLog("[ReadOnlyRegister] Register \"\(register)\" is read only.", type: .error)
            running = false
        } catch CPUError.invalidMemoryAccess(let address) {
            writeToLog("[InvalidMemoryAccess] Memory address \"\(address)\" is outside stack bounds.", type: .error)
            running = false
        } catch CPUError.stackPointerMisaligned(let address) {
            writeToLog("[StackPointerMisaligned] Stack pointer address \"\(address)\" is not quadword aligned.", type: .error)
            running = false
        } catch CPUError.invalidLabel(let label) {
            writeToLog("[InvalidLabel] The referenced label \"\(label)\" does not exist.", type: .error)
            running = false
        } catch {
            writeToLog("Unknown error.", type: .error)
            running = false
        }
        
        cpu.updateStackPointer()
        objectWillChange.send()
    }
}
