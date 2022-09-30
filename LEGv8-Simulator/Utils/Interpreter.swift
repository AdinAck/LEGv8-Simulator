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
    @Published var lexer: Lexer!
    @Published var cpu: CPUModel = CPUModel()
    
    @Published var running: Bool = false
    @Published var programCounter: Int = 0
    
    @Published var lastTouchedRegister: String?
    @Published var lastTouchedMemory: UInt64?
    
    @Published var log: [LogEntry] = []
    
    var labelMap: [String: Int] = [:]
    
    func start(_ text: String) {
        self.lexer = Lexer(text: text)
        self.cpu = CPUModel()
        cpu.updateStackPointer()
        
        programCounter = 0
        log = []
    }
    
    private func literalToUInt64(_ literal: String) throws -> UInt64 {
        if literal.contains("x") {
            if let result = UInt64(String(literal[literal.index(after: literal.firstIndex(of: "x")!)...]), radix: 16) {
                return result
            }
        } else {
            if let result = UInt64(literal) {
                return result
            }
        }
        
        throw CPUError.invalidLiteral(literal)
    }
    
    private func writeToLog(_ message: String, type: LineType = .normal) {
        print(message)
        log.append(LogEntry(id: programCounter, line: lexer.cursor, message: message, type: type))
        programCounter += 1
        objectWillChange.send()
    }
    
    private func isValidLabel(_ label: String) throws {
        guard labelMap.keys.contains(label) else { throw CPUError.invalidLabel(label) }
    }
    
    private func verifyArgumentCount(_ given: Int, _ expected: [Int]) throws {
        guard expected.contains(given) else { throw CPUError.wrongNumberOfArguments(given, expected)}
    }
    
    func b(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        lexer.cursor = labelMap[label]!
    }
    
    func b_eq(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if !cpu.flags[1] { // z == 0
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_ne(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if cpu.flags[1] { // z == 1
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_hs(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if cpu.flags[2] { // c == 1
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_lo(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if !cpu.flags[2] { // c == 0
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_hi(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if !cpu.flags[1] && cpu.flags[2] { // z == 0 && c == 1
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_ls(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if !(!cpu.flags[1] && cpu.flags[2]) { // !(z == 0 && c == 1)
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_ge(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if cpu.flags[0] == cpu.flags[3] { // n == v
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_lt(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if cpu.flags[0] != cpu.flags[3] { // n != v
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_gt(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if !cpu.flags[1] && cpu.flags[0] == cpu.flags[3] { // z == 0 && n == v
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_le(_ label: String) throws {
        // verify label exists
        try isValidLabel(label)
        
        if !(!cpu.flags[1] && cpu.flags[0] == cpu.flags[3]) { // !(z == 0 && n == v)
            lexer.cursor = labelMap[label]!
        }
    }
    
    func step() {
        if programCounter > 1000 {
            writeToLog("[InstructionLimitExceeded] The maximum execution count has been exceeded, this could be due to infinite recursion. You can change this limit in Preferences.", type: .error)
            running = false
            return
        }
        
        let (instruction, arguments) = lexer.parseNextLine()
        
        if instruction == "_end" {
            writeToLog("")
        } else if instruction == "_label" {
            writeToLog(lexer.lines[lexer.cursor - 1], type: .label)
        } else {
            writeToLog(lexer.lines[lexer.cursor - 1])
        }
        
        do {
            switch instruction {
            case "add":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.add(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "addi":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.addi(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "adds":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.adds(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "addis":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.addis(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "sub":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.sub(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "subi":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.subi(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "subs":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.subs(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "subis":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.subis(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "ldur":
                try verifyArgumentCount(arguments.count, [2, 3])
                var offset: UInt64 = 0
                if arguments.count > 2 {
                    offset = UInt64(arguments[2])!
                }
                
                try cpu.ldur(arguments[0], arguments[1], offset)
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "stur":
                try verifyArgumentCount(arguments.count, [2, 3])
                var offset: UInt64 = 0
                if arguments.count > 2 {
                    if let _offset = UInt64(arguments[2]) {
                        offset = _offset
                    }
                }
                
                try cpu.stur(arguments[0], arguments[1], offset)
                lastTouchedRegister = nil
                lastTouchedMemory = cpu.registers[arguments[1]]! + offset
            case "movz":
                try verifyArgumentCount(arguments.count, [4])
                try cpu.movz(arguments[0], UInt64(arguments[1])!, arguments[2], UInt64(arguments[3])!)
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "mov":
                try verifyArgumentCount(arguments.count, [2])
                try cpu.mov(arguments[0], arguments[1])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "and":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.and(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "andi":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.andi(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "orr":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.orr(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "orri":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.orri(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "eor":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.eor(arguments[0], arguments[1], arguments[2])
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "eori":
                try verifyArgumentCount(arguments.count, [3])
                try cpu.eori(arguments[0], arguments[1], literalToUInt64(arguments[2]))
                lastTouchedRegister = arguments[0]
                lastTouchedMemory = nil
            case "b":
                try verifyArgumentCount(arguments.count, [1])
                try b(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.eq":
                try verifyArgumentCount(arguments.count, [1])
                try b_eq(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.ne":
                try verifyArgumentCount(arguments.count, [1])
                try b_ne(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.hs":
                try verifyArgumentCount(arguments.count, [1])
                try b_hs(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.lo":
                try verifyArgumentCount(arguments.count, [1])
                try b_lo(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.hi":
                try verifyArgumentCount(arguments.count, [1])
                try b_hi(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.ls":
                try verifyArgumentCount(arguments.count, [1])
                try b_ls(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.ge":
                try verifyArgumentCount(arguments.count, [1])
                try b_ge(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.lt":
                try verifyArgumentCount(arguments.count, [1])
                try b_lt(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.gt":
                try verifyArgumentCount(arguments.count, [1])
                try b_gt(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "b.le":
                try verifyArgumentCount(arguments.count, [1])
                try b_le(arguments[0])
                lastTouchedRegister = nil
                lastTouchedMemory = nil
            case "_label":
                labelMap[arguments[0]] = lexer.cursor - 1
                step()
            case "_end":
                running = false
                lexer.cursor = 0
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
            writeToLog("[InvalidLiteral] Invalid literal value \"\(literal)\". Literal values may range between 0 and 4095.", type: .error)
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
        } catch CPUError.wrongNumberOfArguments(let given, let expected) {
            writeToLog("[WrongNumberOfArguments] Was given \(given) arguments but expected \(expected).", type: .error)
            running = false
        } catch {
            writeToLog("Unknown error.", type: .error)
            running = false
        }
        
        cpu.updateStackPointer()
        objectWillChange.send()
    }
}
