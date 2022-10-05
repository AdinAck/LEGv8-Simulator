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

enum RunMode {
    case assembling, running, labelling
}

enum AssemblerError: Error {
    case invalidInstruction(_ instruction: String)
    case invalidRegister(_ register: String)
    case invalidLiteral(_ literal: String)
    case invalidLabel(_ label: String)
    case wrongNumberOfArguments(_ given: Int, _ expected: [Int])
}

class Interpreter: ObservableObject {
    @Published var lexer: Lexer!
    @Published var cpu: CPUModel = CPUModel()
    
    @Published var running: Bool = false
    @Published var assembled: Bool = false
    @Published var error: Bool = false
    @Published var programCounter: Int = 0
    var executionLimit: Int = 0
    
    @Published var lastTouchedRegister: String?
    @Published var lastTouchedMemory: Int64?
    
    @Published var log: [LogEntry] = []
    
    var labelMap: [String: Int] = [:]
    
    func buildLabelMap(_ text: String) {
        start(text)
        
        while running {
            step(mode: .labelling)
        }
    }
    
    func assemble(_ text: String) {
        buildLabelMap(text)
        start(text)
        
        error = false
        while running {
            step(mode: .assembling)
        }
        
        cpu = CPUModel()
        
        if !error {
            assembled = true
        }
    }
    
    func start(_ text: String) {
        lexer = Lexer(text: text)
        cpu = CPUModel()
        cpu.updateStackPointer()
        
        programCounter = 0
        log = []
        
        running = true
    }
    
    private func parseLiteral(_ raw: String) throws -> Int64 {
        if raw.contains("x") {
            if let literal = Int64(String(raw[raw.index(after: raw.firstIndex(of: "x")!)...]), radix: 16) {
                return literal
            }
        } else {
            if let literal = Int64(raw) {
                return literal
            }
        }
        
        throw AssemblerError.invalidLiteral(raw)
    }
    
    private func writeToLog(_ message: String, type: LineType = .normal) {
        print(message)
        log.append(LogEntry(id: programCounter, line: lexer.cursor, message: message, type: type))
        programCounter += 1
        
        if type == .error {
            error = true
        }
        
        objectWillChange.send()
    }
    
    // linting helpers
    private func isValidRegister(_ register: String) throws {
        guard cpu.registers.keys.contains(register) else { throw AssemblerError.invalidRegister(register) }
    }
    
    private func isValidLabel(_ label: String) throws {
        guard labelMap.keys.contains(label) else { throw AssemblerError.invalidLabel(label) }
    }
    
    private func verifyArgumentCount(_ given: Int, _ expected: [Int]) throws {
        guard expected.contains(given) else { throw AssemblerError.wrongNumberOfArguments(given, expected)}
    }
    
    private func doStop(mode: RunMode) {
        if mode == .running {
            running = false
        }
    }
    
    // branching
    func cbz(_ source: String, _ label: String) throws {
        if cpu.registers[source]! == 0 {
            lexer.cursor = labelMap[label]!
        }
    }
    
    func cbnz(_ source: String, _ label: String) throws {
        if cpu.registers[source]! != 0 {
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b(_ label: String) throws {
        lexer.cursor = labelMap[label]!
    }
    
    func b_eq(_ label: String) throws {
        if !cpu.flags[1] { // z == 0
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_ne(_ label: String) throws {
        if cpu.flags[1] { // z == 1
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_hs(_ label: String) throws {
        if cpu.flags[2] { // c == 1
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_lo(_ label: String) throws {
        if !cpu.flags[2] { // c == 0
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_hi(_ label: String) throws {
        if !cpu.flags[1] && cpu.flags[2] { // z == 0 && c == 1
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_ls(_ label: String) throws {
        if !(!cpu.flags[1] && cpu.flags[2]) { // !(z == 0 && c == 1)
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_ge(_ label: String) throws {
        if cpu.flags[0] == cpu.flags[3] { // n == v
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_lt(_ label: String) throws {
        if cpu.flags[0] != cpu.flags[3] { // n != v
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_gt(_ label: String) throws {
        if !cpu.flags[1] && cpu.flags[0] == cpu.flags[3] { // z == 0 && n == v
            lexer.cursor = labelMap[label]!
        }
    }
    
    func b_le(_ label: String) throws {
        if !(!cpu.flags[1] && cpu.flags[0] == cpu.flags[3]) { // !(z == 0 && n == v)
            lexer.cursor = labelMap[label]!
        }
    }
    
    func step(mode: RunMode) {
        if programCounter > executionLimit {
            writeToLog("[InstructionLimitExceeded] The maximum execution count has been exceeded, this could be due to infinite recursion. You can change this limit in Preferences.", type: .error)
            running = false
            return
        }
        
        let (instruction, arguments) = lexer.parseNextLine()
        
        if instruction == "_end" {
            writeToLog("")
        } else if instruction == "_label" {
            if mode == .running {
                writeToLog(lexer.lines[lexer.cursor - 1], type: .label)
            } else if mode == .labelling {
                labelMap[arguments[0]] = lexer.cursor - 1
            }
        } else {
            if mode == .running {
                writeToLog(lexer.lines[lexer.cursor - 1])
            }
        }
        
        
        lastTouchedRegister = nil
        lastTouchedMemory = nil
        cpu.touchedFlags = false
        
        if mode == .assembling {
            // assembly
            do {
                switch instruction {
                case "add", "adds", "sub", "subs":
                    try verifyArgumentCount(arguments.count, [3])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                    try isValidRegister(arguments[2])
                case "addi", "addis", "subi", "subis":
                    try verifyArgumentCount(arguments.count, [3])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                    let _ = try parseLiteral(arguments[2])
                case "ldur", "stur":
                    try verifyArgumentCount(arguments.count, [2, 3])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                    if arguments.count > 2 {
                        let _ = try parseLiteral(arguments[2])
                    }
                case "movz", "movk":
                    try verifyArgumentCount(arguments.count, [4])
                    try isValidRegister(arguments[0])
                    let _ = try parseLiteral(arguments[1])
                    guard arguments[2] == "lsl" else { throw AssemblerError.invalidInstruction(arguments[2])}
                    let _ = try parseLiteral(arguments[3])
                case "mov":
                    try verifyArgumentCount(arguments.count, [2])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                case "and", "ands", "orr", "eor":
                    try verifyArgumentCount(arguments.count, [3])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                    try isValidRegister(arguments[2])
                case "andi", "andis", "orri", "eori":
                    try verifyArgumentCount(arguments.count, [3])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                    let _ = try parseLiteral(arguments[2])
                case "lsl", "lsr":
                    try verifyArgumentCount(arguments.count, [3])
                    try isValidRegister(arguments[0])
                    try isValidRegister(arguments[1])
                    let _ = try parseLiteral(arguments[2])
                case "cbz", "cbnz":
                    try verifyArgumentCount(arguments.count, [2])
                    try isValidRegister(arguments[0])
                    try isValidLabel(arguments[1])
                case "b", "b.eq", "b.ne", "b.hs", "b.lo", "b.hi", "b.ls", "b.ge", "b.lt", "b.gt", "b.le":
                    try verifyArgumentCount(arguments.count, [1])
                    try isValidLabel(arguments[0])
                case "_label":
                    step(mode: mode)
                case "_end":
                    running = false
                    lexer.cursor = 0
                default:
                    writeToLog("[UnknownInstruction] Unkown instruction \"\(instruction)\".", type: .error)
                    doStop(mode: mode)
                }
            } catch AssemblerError.invalidInstruction(let instruction) {
                writeToLog("[InvalidInstruction] Invalid instruction \"\(instruction)\".", type: .error)
                doStop(mode: mode)
            } catch AssemblerError.invalidRegister(let register) {
                writeToLog("[InvalidRegister] Invalid register \"\(register)\".", type: .error)
                doStop(mode: mode)
            } catch AssemblerError.invalidLiteral(let literal) {
                writeToLog("[InvalidLiteral] Invalid literal value \"\(literal)\". Literal values may range between 0 and 4095.", type: .error)
                doStop(mode: mode)
            } catch AssemblerError.invalidLabel(let label) {
                writeToLog("[InvalidLabel] The referenced label \"\(label)\" does not exist.", type: .error)
                doStop(mode: mode)
            } catch AssemblerError.wrongNumberOfArguments(let given, let expected) {
                writeToLog("[WrongNumberOfArguments] Was given \(given) arguments but expected \(expected).", type: .error)
                doStop(mode: mode)
            } catch {
                writeToLog("Unknown error.", type: .error)
            }
        } else if mode == .running{
            // execution
            do {
                switch instruction {
                case "add":
                    try cpu.add(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "addi":
                    try cpu.addi(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "adds":
                    try cpu.adds(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "addis":
                    try cpu.addis(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "sub":
                    try cpu.sub(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "subi":
                    try cpu.subi(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "subs":
                    try cpu.subs(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "subis":
                    try cpu.subis(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "ldur":
                    var offset: Int64 = 0
                    if arguments.count > 2 {
                        offset = try parseLiteral(arguments[2])
                    }
                    
                    try cpu.ldur(arguments[0], arguments[1], offset)
                    lastTouchedRegister = arguments[0]
                case "stur":
                    var offset: Int64 = 0
                    if arguments.count > 2 {
                        offset = try parseLiteral(arguments[2])
                    }
                    
                    try cpu.stur(arguments[0], arguments[1], offset)
                    lastTouchedMemory = cpu.registers[arguments[1]]! + offset
                case "movz":
                    try cpu.movz(arguments[0], parseLiteral(arguments[1]), arguments[2], parseLiteral(arguments[3]))
                    lastTouchedRegister = arguments[0]
                case "movk":
                    try cpu.movk(arguments[0], parseLiteral(arguments[1]), arguments[2], parseLiteral(arguments[3]))
                    lastTouchedRegister = arguments[0]
                case "mov":
                    try cpu.mov(arguments[0], arguments[1])
                    lastTouchedRegister = arguments[0]
                case "and":
                    try cpu.and(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "andi":
                    try cpu.andi(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "ands":
                    try cpu.ands(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "andis":
                    try cpu.andis(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "orr":
                    try cpu.orr(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "orri":
                    try cpu.orri(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "eor":
                    try cpu.eor(arguments[0], arguments[1], arguments[2])
                    lastTouchedRegister = arguments[0]
                case "eori":
                    try cpu.eori(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "lsl":
                    try cpu.lsl(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "lsr":
                    try cpu.lsr(arguments[0], arguments[1], parseLiteral(arguments[2]))
                    lastTouchedRegister = arguments[0]
                case "cbz":
                    try cbz(arguments[0], arguments[1])
                case "cbnz":
                    try cbnz(arguments[0], arguments[1])
                case "b":
                    try b(arguments[0])
                case "b.eq":
                    try b_eq(arguments[0])
                case "b.ne":
                    try b_ne(arguments[0])
                case "b.hs":
                    try b_hs(arguments[0])
                case "b.lo":
                    try b_lo(arguments[0])
                case "b.hi":
                    try b_hi(arguments[0])
                case "b.ls":
                    try b_ls(arguments[0])
                case "b.ge":
                    try b_ge(arguments[0])
                case "b.lt":
                    try b_lt(arguments[0])
                case "b.gt":
                    try b_gt(arguments[0])
                case "b.le":
                    try b_le(arguments[0])
                case "_label":
                    step(mode: mode)
                case "_end":
                    running = false
                    lexer.cursor = 0
                default:
                    writeToLog("[UnknownInstruction] Unkown instruction \"\(instruction)\".", type: .error)
                    doStop(mode: mode)
                }
            } catch CPUError.readOnlyRegister(let register) {
                writeToLog("[ReadOnlyRegister] Register \"\(register)\" is read only.", type: .error)
                doStop(mode: mode)
            } catch CPUError.invalidImmediate(let literal) {
                writeToLog("[InvalidLiteral] Invalid literal value \"\(literal)\". Immediate values may range between 0 and 4095.", type: .error)
                doStop(mode: mode)
            } catch CPUError.invalidIndex(let literal) {
                writeToLog("[InvalidLiteral] Invalid literal value \"\(literal)\". Index values may range between -256 and 255 inclusive.", type: .error)
                doStop(mode: mode)
            } catch CPUError.invalidMemoryAccess(let address) {
                writeToLog("[InvalidMemoryAccess] Memory address \"0x\(String(format: "%11X", address))\" is outside stack bounds.", type: .error) // this displays incorrectly - known printf bug
                doStop(mode: mode)
            } catch CPUError.stackPointerMisaligned(let address) {
                writeToLog("[StackPointerMisaligned] Stack pointer address \"\(address)\" is not quadword aligned.", type: .error)
                doStop(mode: mode)
            } catch {
                writeToLog("Unknown error.", type: .error)
                doStop(mode: mode)
            }
        }
        
        cpu.updateStackPointer()
        objectWillChange.send()
    }
}
