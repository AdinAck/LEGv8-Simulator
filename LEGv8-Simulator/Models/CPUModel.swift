//
//  CPUModel.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import Foundation

enum CPUError: Error {
    case invalidLiteral(_ literal: String)
    case readOnlyRegister(_ register: String)
    case invalidMemoryAccess(_ address: UInt64)
    case stackPointerMisaligned(_ address: UInt64)
}

struct Memory: Identifiable, Comparable {
    let id: UInt64
    var value: UInt64
    
    static func < (lhs: Memory, rhs: Memory) -> Bool {
        return lhs.id < rhs.id
    }
}

class CPUModel: ObservableObject {
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
    @Published var registers: [String: UInt64] = [
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
        "sp": 0x7ffffffffc,
        "fp": 0,
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
    @Published var memory: [UInt64: Memory] = [:]
    
    @Published var touchedFlags: Bool = false
    
    init() { }
    
    private func isValidRegister(_ register: String, _ write: Bool = false) throws {
        if write {
            guard register != "xzr" else { throw CPUError.readOnlyRegister(register) }
        }

    }
    
    private func isValidLiteral(_ literal: UInt64) throws {
        guard 0 <= literal && literal <= 0xfff else { throw CPUError.invalidLiteral(String(literal)) }
    }
    
    private func isValidMemoryAddress(_ address: UInt64) throws {
        guard address >= registers["sp"]! else { throw CPUError.invalidMemoryAccess(address) }
    }
    
    private func isStackPointerAligned() throws {
        let address = registers["sp"]!
        guard address % 16 == 0 else { throw CPUError.stackPointerMisaligned(address) }
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
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        let s = (a >> 1) + (b >> 1)
        
        if s > (1 << 31) { // unsigned overflow
            registers[destination] = s << 1 + (a % 2) ^ (b % 2)
        } else {
            registers[destination] = a + b
        }
    }
    
    func addi(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers and immediate
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        let s = (a >> 1) + (b >> 1)
        
        if s > (1 << 31) { // unsigned overflow
            registers[destination] = s << 1 + (a % 2) ^ (b % 2)
        } else {
            registers[destination] = a + b
        }
    }
    
    func adds(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        var result: UInt64 = 0
        
        let s = (a >> 1) + (b >> 1)
        
        if s > (1 << 31) { // unsigned overflow
            result = s << 1 + (a % 2) ^ (b % 2)
            // set c flag
            c = true
        } else {
            result = a + b
        }
        
        // set z and n, and v flags
        if registers[destination]! >> 63 == 0 && result >> 63 == 1 { // signed underflow
            v = true
        }
        
        if result == 0 {
            z = true
        }
        
        if result >> 63 == 1 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        registers[destination] = result
    }
    
    func addis(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers and immediate
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        var result: UInt64 = 0
        
        let s = (a >> 1) + (b >> 1)
        
        if s > (1 << 31) { // unsigned overflow
            result = s << 1 + (a % 2) ^ (b % 2)
            // set c flag
            c = true
        } else {
            result = a + b
        }
        
        // set z and n, and v flags
        if registers[destination]! >> 63 == 0 && result >> 63 == 1 { // signed underflow
            v = true
        }
        
        if result == 0 {
            z = true
        }
        
        if result >> 63 == 1 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        registers[destination] = result
    }
    
    func sub(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        if b > a { // unsigned underflow
            registers[destination] = 1 << 63 + ( 1 << 63 - 1) - (b - a - 1)
        } else {
            registers[destination] = a - b
        }
    }
    
    func subi(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers and immediate
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        if b > a { // unsigned underflow
            registers[destination] = 1 << 63 + ( 1 << 63 - 1) - (b - a - 1)
        } else {
            registers[destination] = a - b
        }
    }
    
    func subs(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = registers[operand2]!
        
        var result: UInt64 = 0
        
        if b > a { // unsigned underflow
            result = 1 << 63 + ( 1 << 63 - 1) - (b - a - 1)
        } else {
            result = a - b
            // set c flag
            c = true
        }
        
        
        // set z and n, and v flags
        if registers[destination]! >> 63 == 1 && result >> 63 == 0 { // signed underflow
            v = true
        }
        
        if result == 0 {
            z = true
        }
        
        if result >> 63 == 1 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        registers[destination] = result
    }
    
    func subis(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers and immediate
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = true
        
        // flags
        var (n, z, c, v) = (false, false, false, false)
        
        // arithmetic
        let a = registers[operand1]!
        let b = operand2
        
        var result: UInt64 = 0
        
        if b > a { // unsigned underflow
            result = 1 << 63 + ( 1 << 63 - 1) - (b - a - 1)
        } else {
            result = a - b
            // set c flag
            c = true
        }
        
        // set z and n, and v flags
        if registers[destination]! >> 63 == 1 && result >> 63 == 0 { // signed underflow
            v = true
        }
        
        if result == 0 {
            z = true
        }
        
        if result >> 63 == 1 {
            n = true
        }
        
        flags = [n, z, c, v]
        
        registers[destination] = result
    }
    
    // data transfer
    func ldur(_ destination: String, _ location: String, _ offset: UInt64) throws {
        let _location = registers[location]! + offset
        
        // verify valid registers and memory address
        try isValidRegister(destination, true)
        try isValidRegister(location)
        try isStackPointerAligned()
        try isValidLiteral(offset)
        try isValidMemoryAddress(_location)
        
        touchedFlags = false
        
        registers[destination] = memory[_location]?.value ?? 0
    }
    
    func stur(_ source: String, _ location: String, _ offset: UInt64) throws {
        let _location = registers[location]! + offset
        
        // verify valid registers and memory address
        try isValidRegister(source)
        try isValidRegister(location)
        try isStackPointerAligned()
        try isValidLiteral(offset)
        try isValidMemoryAddress(_location)
        
        touchedFlags = false
        
        memory[_location] = Memory(id: _location, value: registers[source]!)
    }
    
    // TODO: many more to implement here
    
    func movz(_ destination: String, _ value: UInt64, _ alignment: String, _ shift: UInt64) throws {
        // verify valid registers and immediate
        try isValidRegister(destination, true)
        try isValidLiteral(value)
        
        touchedFlags = false
        
//        if alignment != "lsl" {
//            throw CPUError.invalidInstruction(alignment)
//        }
        if ![0, 16, 32, 48].contains(shift) {
            throw CPUError.invalidLiteral(String(shift))
        }
        
        registers[destination]! = value << shift
    }
    
    func mov(_ destination: String, _ source: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(source)
        
        touchedFlags = false
        
        registers[destination]! = registers[source]!
    }
    
    // logical
    func and(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! & registers[operand2]!
    }
    
    func andi(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! & operand2
    }
    
    func ands(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
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
        
        registers[destination] = result
    }
    
    func andis(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
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
        
        registers[destination] = result
    }
    
    func orr(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! | registers[operand2]!
    }
    
    func orri(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! | operand2
    }
    
    func eor(_ destination: String, _ operand1: String, _ operand2: String) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidRegister(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! ^ registers[operand2]!
    }
    
    func eori(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! ^ operand2
    }
    
    func lsl(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! << operand2
    }
    
    func lsr(_ destination: String, _ operand1: String, _ operand2: UInt64) throws {
        // verify valid registers
        try isValidRegister(destination, true)
        try isValidRegister(operand1)
        try isValidLiteral(operand2)
        
        touchedFlags = false
        
        registers[destination] = registers[operand1]! >> operand2
    }
}
