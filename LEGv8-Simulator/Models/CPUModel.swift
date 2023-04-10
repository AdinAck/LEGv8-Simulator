//
//  CPUModel.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import Foundation

enum CPUError: Error {
    case invalidImmediate(_ literal: String)
    case invalidIndex(_ literal: String)
    case invalidMemoryAccess(_ address: Int64)
    case stackPointerMisaligned(_ address: Int64)
}

class Memory: ObservableObject, Identifiable, Comparable {
    let id: Int64
    @Published var value: Int64
    @Published var displayMode: String = "H"
    
    static func < (lhs: Memory, rhs: Memory) -> Bool {
        return lhs.id < rhs.id
    }
    
    static func == (lhs: Memory, rhs: Memory) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: Int64, value: Int64) {
        self.id = id
        self.value = value
    }
}

class CPUModel: ObservableObject, CustomStringConvertible {
    /*
     x0-x7:     arguments/results
     x8:        indirect result location register
     x9-x15:    temporary registers
     ip0 (x16): first intra-procedure-call scratch register; other times used as temporary register
     ip1 (x17)  second intra-procedure-call scratch register; other times used as temporary register
     x18:       platform register for platform independent code; otherwise a temporary register
     x19-x27:   callee-saved registers
     sp (x28):  stack pointer
     fp (x29):  frame pointer
     lr (x30):  link register (return address)
     xzr:       the constant value 0
     */
    @Published var registers: [String: Int64] = [
        "x0": 0,
        "x1": 0,
        "x2": 0,
        "x3": 0,
        "x4": 0,
        "x5": 0,
        "x6": 0,
        "x7": 0,
        "x8": 0,
        "x9": 0,
        "x10": 0,
        "x11": 0,
        "x12": 0,
        "x13": 0,
        "x14": 0,
        "x15": 0,
        "x16": 0,
        "x17": 0,
        "x18": 0,
        "x19": 0,
        "x20": 0,
        "x21": 0,
        "x22": 0,
        "x23": 0,
        "x24": 0,
        "x25": 0,
        "x26": 0,
        "x27": 0,
        "sp": 0x7ffffffff0,
        "fp": 0x7ffffffff0,
        "lr": 0,
        "xzr": 0,
    ]
    
    /*
     Z: Zero     - result was 0
     N: Negative - result had 1 is MSB
     C: Carry    - result had carryout from MSB
     V: Overflow - result overflowed
     */
    @Published var flags: [Bool] = [false, false, false, false]
    @Published var memory: [Int64: Memory] = [:]
    @Published var heapPointer: Int64 = 0
    
    @Published var touchedFlags: Bool = false
    
    public var description: String {
        var reg: String = ""
        
        for register in registers.keys.sorted(by: { lhs, rhs in CPUModel.registerSort(lhs: lhs, rhs: rhs)}) {
            reg += "\(register): 0x\(String(format: "%llX", registers[register]!))\n"
        }
        
        var mem: String = ""
        
        for memory in self.memory.values.sorted() {
            mem += "0x\(String(format: "%llX", memory.id)): 0x\(String(format: "%llX", memory.value))\n"
        }
        
        return "Registers:\n\(reg)\nMemory:\n\(mem)\nFlags: \(flags)"
    }
    
    public static func registerSort(lhs: String, rhs: String) -> Bool {
        if lhs == "xzr" {
            return false
        } else if rhs == "xzr" {
            return true
        } else if lhs.contains("x") && rhs.contains("x") {
            return Int(lhs[lhs.index(after: lhs.startIndex)...])! < Int(rhs[rhs.index(after: rhs.startIndex)...])!
        } else if lhs.contains("x") {
            return true
        } else if rhs.contains("x") {
            return false
        } else {
            let order = ["sp": 0, "fp": 1, "lr": 2]
            return order[lhs]! < order[rhs]!
        }
    }
    
    private func isValidImmediate(_ literal: Int64) throws {
        guard 0 <= literal && literal <= 0xfff else { throw CPUError.invalidImmediate(String(literal)) }
    }
    
    private func isValidIndex(_ literal: Int64) throws {
        guard -0xff <= literal && literal < 0xff else { throw CPUError.invalidIndex(String(literal)) }
    }
    
    private func isValidMemoryAddress(_ address: Int64, write: Bool = false) throws {
        if write {
            guard (address >= registers["sp"]! && address <= registers["fp"]!) || address <= heapPointer else { throw CPUError.invalidMemoryAccess(address) }
        }
    }
    
    private func isStackPointerAligned() throws {
        let address = registers["sp"]!
        guard address % 16 == 0 else { throw CPUError.stackPointerMisaligned(address) }
    }
    
    private func setRegister(_ register: String, _ value: Int64) {
        if !["xzr"].contains(register) {
            registers[register]! = value
        }
    }
    
    func updateStackPointer() {
        // update memory to display where sp has been
        let sp = registers["sp"]!
        guard let _ = memory[sp] else {
            memory[sp] = Memory(id: sp, value: 0)
            return
        }
    }
    
    // arithmetic instructions
    func add(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        let s = (a >> 1) + (b >> 1)
        var result: Int64 = 0
        
        if (a < 0 && b < 0 && result > 0) || (a > 0 && b > 0 && result < 0) { // signed underflow and overflow
            result = s << 1 + (a % 2) ^ (b % 2)
        } else {
            result = a &+ b
        }
        
        setRegister(destination, result)
    }
    
    func addi(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        let s = (a >> 1) + (b >> 1)
        var result: Int64 = 0
        
        if (a < 0 && b < 0 && result > 0) || (a > 0 && b > 0 && result < 0) { // signed underflow and overflow
            result = s << 1 + (a % 2) ^ (b % 2)
        } else {
            result = a &+ b
        }
        
        setRegister(destination, result)
    }
    
    func adds(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        let s = (a >> 1) + (b >> 1)
        let result = a &+ b
        
        if (a < 0 && b < 0 && result > 0) || (a > 0 && b > 0 && result < 0) { // signed underflow and overflow
            // set v flag
            v = true
        }
        
        // set z and n, and c flags
        if s > (1 << 62 + (1 << 62 - 2)) { // unsigned overflow?
            if s < (1 << 63) { // 1 or 2 away from overflow
                if (a % 2) != 0 && (b % 2) != 0 { // push over edge to overflow
                    c = true
                }
            } else { // well over threshold
                c = true
            }
        }
        
        if result == 0 {
            z = true
        }
        
        if result < 0 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        setRegister(destination, result)
    }
    
    func addis(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        let s = (a >> 1) + (b >> 1)
        let result = a &+ b
        
        if (a < 0 && b < 0 && result > 0) || (a > 0 && b > 0 && result < 0) { // signed underflow and overflow
            // set v flag
            v = true
        }
        
        // set z and n, and c flags
        if s > (1 << 62 + (1 << 62 - 2)) { // unsigned overflow?
            if s < (1 << 63) { // 1 or 2 away from overflow
                if (a % 2) != 0 && (b % 2) != 0 { // push over edge to overflow
                    c = true
                }
            } else { // well over threshold
                c = true
            }
        }
        
        if result == 0 {
            z = true
        }
        
        if result < 0 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        setRegister(destination, result)
    }
    
    func sub(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        let result = a &- b
        
        setRegister(destination, result)
    }
    
    func subi(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        let result = a &- b
        
        setRegister(destination, result)
    }
    
    func subs(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        let result = a &- b
        
        if (a < 0 && b > 0 && result > 0) || (a > 0 && b < 0 && result < 0) { // signed underflow and overflow
            // set v flag
            v = true
        }
        
        // set z and n, and c flags
        if a >= b {
            c = true
        }
        
        if result == 0 {
            z = true
        }
        
        if result < 0 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        setRegister(destination, result)
    }
    
    func subis(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        let result = a &- b
        
        if (a < 0 && b > 0 && result > 0) || (a > 0 && b < 0 && result < 0) { // signed underflow and overflow
            // set v flag
            v = true
        }
        
        // set z and n, and c flags
        if a >= b { // unsigned overflow
            c = true
        }
        
        if result == 0 {
            z = true
        }
        
        if result < 0 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        setRegister(destination, result)
    }
    
    func mul(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        let result = a &* b
        
        setRegister(destination, result)
    }
    
    // data transfer
    func ldur(_ destination: String, _ location: String, _ offset: Int64) throws {
        let _location = registers[location]! + offset
        
        // verify valid memory address
        try isStackPointerAligned()
        try isValidIndex(offset)
        try isValidMemoryAddress(_location)
        
        touchedFlags = false
        
        setRegister(destination, memory[_location]?.value ?? 0)
    }
    
    func stur(_ source: String, _ location: String, _ offset: Int64) throws {
        let _location = registers[location]! + offset
        
        // verify valid memory address
        try isStackPointerAligned()
        try isValidIndex(offset)
        try isValidMemoryAddress(_location, write: true)
        
        touchedFlags = false
        
        memory[_location] = Memory(id: _location, value: registers[source]!)
    }
    
    // TODO: many more to implement here
    
    func movz(_ destination: String, _ value: Int64, _ alignment: String, _ shift: Int64) throws {
        try isValidImmediate(value)
        
        touchedFlags = false
        
        if ![0, 16, 32, 48].contains(shift) {
            throw CPUError.invalidImmediate(String(shift))
        }
        
        setRegister(destination, value << shift)
    }
    
    func movk(_ destination: String, _ value: Int64, _ alignment: String, _ shift: Int64) throws {
        try isValidImmediate(value)
        
        touchedFlags = false
        
        if ![0, 16, 32, 48].contains(shift) {
            throw CPUError.invalidImmediate(String(shift))
        }
        
        setRegister(destination, ((registers[destination]! << shift) >> shift) + value << shift)
    }
    
    // logical
    func and(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = false
        
        setRegister(destination, registers[operand1]! & registers[operand2]!)
    }
    
    func andi(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        setRegister(destination, registers[operand1]! & operand2)
    }
    
    func ands(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        let result = registers[operand1]! & registers[operand2]!
        
        // check z flag
        if result == 0 {
            z = true
        }
        
        // TODO: more flag checks may be needed
        
        flags = [n, z, c, v]
        
        setRegister(destination, result)
    }
    
    func andis(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        let result = registers[operand1]! & operand2
        
        // check z flag
        if result == 0 {
            z = true
        }
        
        // TODO: more flag checks may be needed
        
        flags = [n, z, c, v]
        
        setRegister(destination, result)
    }
    
    func orr(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = false
        
        setRegister(destination, registers[operand1]! | registers[operand2]!)
    }
    
    func orri(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        setRegister(destination, registers[operand1]! | operand2)
    }
    
    func eor(_ destination: String, _ operand1: String, _ operand2: String) throws {
        touchedFlags = false
        
        setRegister(destination, registers[operand1]! ^ registers[operand2]!)
    }
    
    func eori(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        setRegister(destination, registers[operand1]! ^ operand2)
    }
    
    func lsl(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        let a = registers[operand1]!
        
        setRegister(destination, a < 0 ? (a &- (1 << 63)) << 1 : a << operand2)
    }
    
    func lsr(_ destination: String, _ operand1: String, _ operand2: Int64) throws {
        try isValidImmediate(operand2)
        
        touchedFlags = false
        
        let a = registers[operand1]!
        
        setRegister(destination, a < 0 ? ((a &- (1 << 63)) >> operand2) &+ (1 << (63 - operand2)) : a >> operand2)
    }
    
    func lda(_ destination: String, _ address: Int64) {
        registers[destination] = address
    }
}
