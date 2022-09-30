//
//  RegisterView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/30/22.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    var body: some View {
        VStack {
            HStack {
                Text("Registers")
                    .font(.title)
                    .padding(.leading)
                    .padding(.top)
                Spacer()
            }
            
            FlagView()
                .environmentObject(interpreter)
            
            HStack {
                let registers: [String] = interpreter.cpu.registers.keys.sorted(by: { lhs, rhs in
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
                } )
                List(registers[..<16], id: \.self) { name in
                    HStack {
                        Text(name)
                            .font(.custom("Menlo Regular", size: 12))
                        
                        Spacer()
                        
                        HStack {
                            if interpreter.lastTouchedRegister == name {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                            
                            let value = interpreter.cpu.registers[name]!
                            
                            Text("0x\(String(format: "%llX", value))")
                                .font(.custom("Menlo Regular", size: 12))
                                .textSelection(.enabled)
                                .help("\(value)")
                        }
                    }
                }
                
                List(registers[16...], id: \.self) { name in
                    HStack {
                        Text(name)
                            .font(.custom("Menlo Regular", size: 12))
                        Spacer()
                        HStack {
                            if interpreter.lastTouchedRegister == name {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                            
                            let value = interpreter.cpu.registers[name]!
                            
                            Text("0x\(String(format: "%llX", value))")
                                .font(.custom("Menlo Regular", size: 12))
                                .textSelection(.enabled)
                                .help("\(value)")
                        }
                    }
                }
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
