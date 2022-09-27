//
//  LEGv8_SimulatorApp.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import SwiftUI

@main
struct LEGv8_SimulatorApp: App {
    @StateObject var interpreter: Interpreter = Interpreter()
    @StateObject var fileio: FileIO = FileIO()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(interpreter)
                .environmentObject(fileio)
        }.commands {
            CommandMenu("File") {
                Button("Save") {
                    if let url = fileio.url {
//                        do {
                        url.startAccessingSecurityScopedResource()
                        let fileManager = FileManager.default
                        let _ = fileManager.urls(for: .userDirectory, in: .allDomainsMask)
                        print(url.relativeString)
                        try! fileManager.removeItem(at: url)
                        try! fileio.text.write(to: url, atomically: true, encoding: .utf8)
                        url.stopAccessingSecurityScopedResource()
//                        } catch {
//                            print("Failed to save file.")
//                        }
                    }
                }
                .keyboardShortcut("s")
            }
            
            CommandMenu("Control") {
                Button("Step") {
                    if !interpreter.running {
                        interpreter.start(fileio.text)
                        interpreter.running = true
                    }
                        interpreter.step()
                }
                .keyboardShortcut("n")
                
                Button(interpreter.running ? "Continue" : "Run") {
                    interpreter.start(fileio.text)
                    interpreter.running = true
                    
                    while interpreter.running {
                        interpreter.step()
                    }
                }
                .keyboardShortcut("r")
                
                Button("Stop") {
                    interpreter.running = false
                }
                .disabled(!interpreter.running)
            }
        }
    }
}
