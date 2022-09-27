//
//  ContentView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import SwiftUI
import SwiftyMonaco

struct ContentView: View {
    // monaco
    @State var reloadFlag: Bool = false
    let syntax = SyntaxHighlight(title: "asm", fileURL: Bundle.main.url(forResource: "asm", withExtension: "js")!)
    
    @EnvironmentObject var interpreter: Interpreter
    @EnvironmentObject var fileio: FileIO
    
    var body: some View {
        HSplitView {
            VSplitView {
                SwiftyMonaco(text: $fileio.text, reloadFlag: $reloadFlag)
                    .syntaxHighlight(syntax)
                    .smoothCursor(true)
                    .cursorBlink(.smooth)
                
                ConsoleView()
                    .environmentObject(interpreter)
            }
            
            VStack {
                Text("Registers")
                    .font(.title)
                
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
                                    .help("\(value)")
                            }
                        }
                    }
                }
                
                Divider()
                
                Text("Memory")
                    .font(.title)
                
                Table(interpreter.cpu.memory.values.sorted()) {
                    TableColumn("Address") { memory in
                        HStack {
                            if interpreter.cpu.registers["sp"]! == memory.id {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.green)

                            }
                            
                            Text("0x\(String(format: "%llX", memory.id))")
                                .font(.custom("Menlo Regular", size: 12))
                        }
                    }
                    
                    TableColumn("Distance from SP") { memory in
                        Text("\(memory.id - interpreter.cpu.registers["sp"]!)")
                            .font(.custom("Menlo Regular", size: 12))
                    }
                    
                    TableColumn("Value") { memory in
                        HStack {
                            if interpreter.lastTouchedMemory == memory.id {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("0x\(String(format: "%llX", memory.value))")
                                .font(.custom("Menlo Regular", size: 12))
                                .help("\(memory.value)")
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    fileio.openFile()
                    reloadFlag = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
            
            ToolbarItemGroup {
                    Button {
                        if !interpreter.running {
                            interpreter.start(fileio.text)
                            interpreter.running = true
                        }
                        interpreter.step()
                    } label: {
                        Image(systemName: "forward.end.fill")
                    }
                    .help("Step")
                
                    Button {
                        interpreter.start(fileio.text)
                        interpreter.running = true
                        
                        while interpreter.running {
                            interpreter.step()
                        }
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .help("Run/Continue")
                
                    Button {
                        interpreter.running = false
                    } label: {
                        VStack {
                            Image(systemName: "stop.fill")
                        }
                    }
                    .disabled(!interpreter.running)
                    .help("Stop")
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
